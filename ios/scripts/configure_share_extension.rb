#!/usr/bin/env ruby
# Idempotently wires the checked-in ShareExtension sources into Runner.xcodeproj.
# Run this after Flutter has generated its Swift Package Manager integration so
# the extension can link the same FlutterGeneratedPluginSwiftPackage as Runner.

require 'xcodeproj'

root = File.expand_path('..', __dir__)
project_path = File.join(root, 'Runner.xcodeproj')
project = Xcodeproj::Project.open(project_path)

runner = project.targets.find { |target| target.name == 'Runner' }
raise 'Runner target not found' unless runner

extension = project.targets.find { |target| target.name == 'ShareExtension' }
extension ||= project.new_target(:app_extension, 'ShareExtension', :ios, '15.0')

main_group = project.main_group
share_group = main_group.find_subpath('ShareExtension', true)
share_group.set_source_tree('<group>')
share_group.set_path('ShareExtension')

swift = share_group.files.find { |f| f.path == 'ShareViewController.swift' } || share_group.new_file('ShareViewController.swift')
plist = share_group.files.find { |f| f.path == 'Info.plist' } || share_group.new_file('Info.plist')
entitlements = share_group.files.find { |f| f.path == 'ShareExtension.entitlements' } || share_group.new_file('ShareExtension.entitlements')

base_group = share_group.groups.find { |g| g.path == 'Base.lproj' } || share_group.new_group('Base', 'Base.lproj')
storyboard = base_group.files.find { |f| f.path == 'MainInterface.storyboard' } || base_group.new_file('MainInterface.storyboard')

unless extension.source_build_phase.files_references.include?(swift)
  extension.source_build_phase.add_file_reference(swift)
end
unless extension.resources_build_phase.files_references.include?(storyboard)
  extension.resources_build_phase.add_file_reference(storyboard)
end

runner_bundle_id = runner.build_configurations.map { |config| config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] }
  .compact
  .find { |value| !value.to_s.empty? } || 'com.naylahknee.nanynany'
extension_bundle_id = "#{runner_bundle_id}.ShareExtension"

extension.build_configurations.each do |config|
  settings = config.build_settings
  settings['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
  settings['CODE_SIGN_ENTITLEMENTS'] = 'ShareExtension/ShareExtension.entitlements'
  settings['CODE_SIGN_STYLE'] = 'Automatic'
  settings['CURRENT_PROJECT_VERSION'] = '$(FLUTTER_BUILD_NUMBER)'
  settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  settings['INFOPLIST_FILE'] = 'ShareExtension/Info.plist'
  settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
  settings['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks']
  settings['MARKETING_VERSION'] = '$(FLUTTER_BUILD_NAME)'
  settings['PRODUCT_BUNDLE_IDENTIFIER'] = extension_bundle_id
  settings['PRODUCT_NAME'] = '$(TARGET_NAME)'
  settings['SKIP_INSTALL'] = 'YES'
  settings['SWIFT_VERSION'] = '5.0'
  settings['TARGETED_DEVICE_FAMILY'] = '1,2'
end

runner.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
end

# receive_sharing_intent 1.9 is SPM-only. Flutter generates a local aggregate
# product called FlutterGeneratedPluginSwiftPackage and links it to Runner.
# The Share Extension imports RSIShareViewController, so it must explicitly link
# that same product as well.
flutter_package = runner.package_product_dependencies.find do |dependency|
  dependency.product_name == 'FlutterGeneratedPluginSwiftPackage'
end

unless flutter_package
  raise 'FlutterGeneratedPluginSwiftPackage not found. Run Flutter iOS config generation before this script.'
end

extension_package = extension.package_product_dependencies.find do |dependency|
  dependency.product_name == flutter_package.product_name
end

unless extension_package
  extension_package = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  extension_package.product_name = flutter_package.product_name
  extension_package.package = flutter_package.package
  extension.package_product_dependencies << extension_package
end

unless extension.frameworks_build_phase.files.any? do |build_file|
  build_file.respond_to?(:product_ref) && build_file.product_ref == extension_package
end
  build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
  build_file.product_ref = extension_package
  extension.frameworks_build_phase.files << build_file
end

# Runner must build and embed the extension.
unless runner.dependencies.any? { |dependency| dependency.target == extension }
  runner.add_dependency(extension)
end

embed_phase = runner.copy_files_build_phases.find { |phase| phase.name == 'Embed App Extensions' }
unless embed_phase
  embed_phase = runner.new_copy_files_build_phase('Embed App Extensions')
  embed_phase.dst_subfolder_spec = '13'
end
unless embed_phase.files_references.include?(extension.product_reference)
  build_file = embed_phase.add_file_reference(extension.product_reference)
  build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
end

# Keep extension embedding ahead of Flutter's Thin Binary phase to avoid the
# dependency cycle documented by receive_sharing_intent.
thin_index = runner.build_phases.index { |phase| phase.respond_to?(:name) && phase.name == 'Thin Binary' }
embed_index = runner.build_phases.index(embed_phase)
if thin_index && embed_index && embed_index > thin_index
  runner.build_phases.delete(embed_phase)
  runner.build_phases.insert(thin_index, embed_phase)
end

project.save
puts "ShareExtension configured with bundle id #{extension_bundle_id} and Flutter SPM package linked."
