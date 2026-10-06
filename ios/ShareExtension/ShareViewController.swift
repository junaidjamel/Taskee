import receive_sharing_intent

/// Native iOS doorway into NanyNany's existing Flutter share ingestion pipeline.
/// RSIShareViewController copies supported attachments into the shared App Group
/// container and opens the host app through the ShareMedia URL scheme.
final class ShareViewController: RSIShareViewController {}
