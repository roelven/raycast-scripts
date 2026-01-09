# Raycast Scripts

A collection of AI-powered productivity scripts for [Raycast](https://www.raycast.com/) using OpenAI's GPT models.

## Scripts

### Prompt my prompt
Transforms your clipboard content into a professional, production-ready prompt using GPT-4o-mini.

- **Command**: Prompt my prompt
- **Icon**: 🤖
- **Package**: Prompt Tools
- **Usage**: Copy text to clipboard, run the script, and get an improved prompt copied back

### Translate to German
Translates clipboard text into grammatically correct German.

- **Command**: Translate to German
- **Icon**: 📝
- **Package**: Language Tools
- **Usage**: Copy text to clipboard, run the script, and get the German translation copied back

## Setup

### Prerequisites
- [Raycast](https://www.raycast.com/) installed on macOS
- OpenAI API key ([Get one here](https://platform.openai.com/api-keys))
- `jq` installed (`brew install jq`)

### Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/roelven/raycast-scripts.git
   cd raycast-scripts
   ```

2. Copy the workflow handler to your Raycast bin directory:
   ```bash
   mkdir -p ~/.raycast/bin
   cp bin/llm-workflow.sh ~/.raycast/bin/
   chmod +x ~/.raycast/bin/llm-workflow.sh
   ```

3. Configure your OpenAI API key in each script:
   - Edit `scripts/improve_prompt.sh` and replace `OPENAI_API_KEY="XXXXXX"` with your actual API key
   - Edit `scripts/translate_to_german.sh` and replace `OPENAI_API_KEY="XXXXX"` with your actual API key

4. Import scripts into Raycast:
   - Open Raycast preferences
   - Go to Extensions → Script Commands
   - Click "Add Directories" and select the `scripts` folder from this repo

## Architecture

The scripts use a shared workflow handler (`bin/llm-workflow.sh`) that:
- Reads clipboard content
- Validates input (checks for empty content, single words, hash patterns)
- Makes API calls to OpenAI with configured system prompts
- Shows a spinner during processing
- Copies results back to clipboard
- Displays notifications via Raycast

Each script configures the workflow with:
- Model selection (gpt-4o-mini)
- System prompt
- Temperature settings
- Success/spinner messages

## Security

This repository uses a comprehensive `.gitignore` to prevent accidental exposure of:
- Environment files (`.env`, `.env.*`)
- API keys and tokens
- Private keys (`.key`, `.pem`, `.p12`, `.pfx`)
- SSH keys
- Credential files

**Important**: Never commit your actual API keys. Use environment variables or secure storage like macOS Keychain in production.

## Author

Roel van der Ven
- Website: [roelvanderven.com](https://roelvanderven.com)

## License

MIT
