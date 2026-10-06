import OpenAI from 'openai';

const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  if (!process.env.OPENAI_API_KEY) {
    res.status(500).json({ error: 'OPENAI_API_KEY is not configured' });
    return;
  }

  const { url, title, creator, platform, summary } = req.body ?? {};
  if (!url) {
    res.status(400).json({ error: 'url is required' });
    return;
  }

  try {
    const response = await client.responses.create({
      model: 'gpt-5-mini',
      input: [
        {
          role: 'system',
          content: [
            {
              type: 'input_text',
              text: 'You enrich saved developer-learning resources. Be concise and practical. Focus on why the resource matters, when it should resurface, and the technologies/topics involved. Do not invent facts that are not supported by the supplied metadata.'
            }
          ]
        },
        {
          role: 'user',
          content: [
            {
              type: 'input_text',
              text: JSON.stringify({ url, title, creator, platform, summary })
            }
          ]
        }
      ],
      text: {
        format: {
          type: 'json_schema',
          name: 'resource_enrichment',
          strict: true,
          schema: {
            type: 'object',
            additionalProperties: false,
            required: ['summary', 'whyUseful', 'useWhen', 'topics', 'technologies'],
            properties: {
              summary: { type: 'string' },
              whyUseful: { type: 'string' },
              useWhen: { type: 'string' },
              topics: { type: 'array', items: { type: 'string' } },
              technologies: { type: 'array', items: { type: 'string' } }
            }
          }
        }
      }
    });

    res.status(200).json(JSON.parse(response.output_text));
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Could not enrich resource' });
  }
}
