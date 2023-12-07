# RHEL9VLLM
vLLM API server running Red Hat Enterprise Linux 9 in a Docker container.

# Edit the .env file to change the following variables before running the docker compose command.
# (default values are shown below)
# See the vllm documentation for more arguments https://docs.vllm.ai/en/latest/models/engine_args.html

    MODEL='TheBloke/dolphin-2.2.1-mistral-7B-AWQ'
    QUANTIZATION='awq'
    DTYPE='auto'
    MAX_MODEL_LEN='4096'
    API_SERVER='openai.api_server'

## Build and run the vllm-rhel9-api container using docker-compose
docker compose up -d

# Stop the container using docker-compose
docker compose stop

# Start the vllm-rhel9-api container without changes using docker-compose
docker compose start
