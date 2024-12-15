import json
import os
import chromadb
import autogen
from autogen import AssistantAgent, UserProxyAgent
from autogen.agentchat.contrib.retrieve_user_proxy_agent import RetrieveUserProxyAgent
from autogen.retrieve_utils import TEXT_FORMATS

# Load config list
config_list = autogen.config_list_from_json(env_or_file="OAI_CONFIG_LIST.json")
assert len(config_list) > 0
print("Models to use:", [config_list[i]["model"] for i in range(len(config_list))])

print("Accepted file formats for `docs_path`:", TEXT_FORMATS)

# Initialize AssistantAgent to handle general queries and greetings
assistant = AssistantAgent(
    name="assistant",
    system_message="You are a healthcare assistant. First provide a calming message for non-urgent symptoms "
                   "For medical symptoms, suggest medicines with prices and images. All responses should be in JSON format. "
                   "Remind the user to consult a doctor for confirmation. Handle general queries normally"
                   "In the JSON, the calming message should be under the key 'message', medications as 'medicines' and remineder message as 'disclaimer'",
    llm_config={
        "timeout": 600,
        "cache_seed": 42,
        "config_list": config_list,
    },
)

classifier = AssistantAgent(
    name="classifier",
    system_message="You are a classifier. The output would be in JSON format" ,
    llm_config={
        "timeout": 600,
        "cache_seed": 42,
        "config_list": config_list,
    },
)

# File with product data for medical queries
corpus_file = "../ProductCatelog.xml"

# Initialize RetrieveUserProxyAgent to handle medical queries (RAG-enabled)
ragproxyagent = RetrieveUserProxyAgent(
    name="ragproxyagent",
    human_input_mode="NEVER",
    max_consecutive_auto_reply=10,
    retrieve_config={
        "task": "code",  # This agent handles medical-related queries
        "docs_path": corpus_file,
        "chunk_token_size": 2000,
        "model": config_list[0]["model"],
        "client": chromadb.PersistentClient(path="/tmp/chromadb"),
        "get_or_create": True,
        "embedding_model": "all-MiniLM-L6-v2",
    },
    code_execution_config=False,
)

# Initialize UserProxyAgent as the main entry point for user queries
user_proxy = UserProxyAgent(
    name="UserProxy",
    human_input_mode="NEVER",  # Fully automated interaction
    code_execution_config={
        "last_n_messages": 1,
        "work_dir": "tasks",
        "use_docker": False,
    },
)

# Function to classify the user input dynamically using UserProxyAgent
def classify_intent(user_input):
    # Ask the UserProxyAgent (LLM) to classify the input
    classification_prompt = (
        f"Classify the following input as either 'medical', 'greeting', or 'general':\n\n"
        f"Input: {user_input}\n"
        "Please provide the classification in one word."
    )

    # Call the assistant (or user proxy) to generate the classification
    classification_response = user_proxy.initiate_chat(
        classifier, message=classification_prompt, max_turns=1, summary_method="last_msg"
    )
    print(f"classification_response: {classification_response}")

    summary = classification_response.summary

    print(f"summary: {summary}")

    clean_response = summary.strip().strip("```json").strip("```")

    # Clean the response by removing markdown code block symbols (```json and ```)
    # clean_response = classification_response.message.strip().strip("```json").strip("```")
    
    # Parse the cleaned JSON response
    try:
        response_json = json.loads(clean_response)
        classification = response_json.get("classification", "").lower()
        print(f"classification: {classification}")
    except json.JSONDecodeError:
        # Handle case where the response isn't valid JSON
        classification = "general"
    
    return classification

# Main logic for handling queries
def handle_user_query(user_input):
    # Classify the intent dynamically
    print("XYZ ")
    print(f"user_input: {user_input}")
    intent = classify_intent(user_input)
    print(f"intent: {intent}")

    if intent == "greeting":
        return {"message": "Hello! How can I assist you today with your health concerns?"}

    if intent == "medical":
        # Route medical queries to RetrieveUserProxyAgent for symptom analysis
        chat_result = ragproxyagent.initiate_chat(
            assistant, message=ragproxyagent.message_generator, problem=user_input, n_results=5
        )
        return chat_result
    
    # # Handle general queries with AssistantAgent
    #general_response = assistant.initiate_chat(user_proxy, message=user_input, max_turns=1, summary_method="last_msg")
    general_response = user_proxy.initiate_chat(recipient=assistant, message=user_input, max_turns=1, summary_method="last_msg")
    return general_response


# Simulated interaction
def user_interaction(user_input):
    response = handle_user_query(user_input)
    print("Response:", response)

# Example usage with different user inputs
#user_interaction("Hi")                  # Should trigger greeting response
#user_interaction("I have a headache")   # Should trigger medical query to RetrieveUserProxyAgent
user_interaction("Tell me about AI")    # Should trigger general query handled by AssistantAgent
