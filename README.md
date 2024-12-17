# Pulse AI
## Personal Health Assistant Chatbot

This is a Flutter-based Personal Health Assistant application that allows users to chat with an AI healthcare assistant. Users can describe their symptoms, ask health-related questions, and receive AI-generated responses.  The backend is built using Flask, AutoGen, and OpenAI to provide intelligent responses and healthcare suggestions.

## Features

- Chat with an AI-based health assistant for personalized health recommendations.
- Fetches medicine information, including prices and images.
- Displays AI-generated disclaimers advising users to consult a doctor for clarification.

## Project Structure

- **chatbot_screen.dart**: Manages the chat interface and communication with the backend.
- **app.py**: FastAPI backend that integrates with AutoGen and OpenAI for generating responses and analyzing images.
- **main.dart**: Main entry point of the Flutter app.
- **MedicalProductsScreen**: Shows a list of medical products for user convenience.

## Prerequisites
Before you can run the app, make sure the following dependencies are installed:

### General Requirements

1. **Flutter**: Download and install Flutter SDK from [Flutter's official website](https://flutter.dev/docs/get-started/install).
2. **Dart**: Dart is included with Flutter, so you don’t need to install it separately.
3. **Python 3.7+**: Required for running the FastAPI backend.
4. **OpenAI API Key**: Register and get your API key from [OpenAI's website](https://platform.openai.com/signup/).
5. **AutoGen Library**: Install via pip to enable chat with AI.
6. **Pg-vector**: Download for semantic retrieval features

### Flutter Packages
In your Flutter project directory, to add the dependencies, run:
`flutter pub get`

### Python Libraries
In your backend folder, create a virtual environment and install the necessary Python packages:

# Create a virtual environment (optional)
```python -m venv venv```
```venv\Scripts\activate```

# Install Flask and other necessary libraries
`pip install flask openai autogen chromadb markdownify pypdf multi-part`

### Setup OpenAI and AutoGen Configuration: 
Create a configuration file named OAI_CONFIG_LIST.json in backend folder and add your OpenAI API credentials to it:

```
[
  {
    "model": "gpt-4o-mini",
    "api_key": "your_openai_api_key_here"
  }
]
```


# Setting Up the Backend

### In your project directory, navigate to the backend folder.
- To navigate to backend directory, run:
`cd backend`

- Run the Flask server with the following command:
`python app.py`


## Running the Flutter App

### Open a new terminal & navigate to your lib folder.
- Run the Flutter app with the following command:
`flutter run`


## Future Enhancements 
- Extend backend functionality for more comprehensive healthcare responses.
- Add database integration to store user queries and responses.
- Implement more AI models and image analysis techniques.
- Services like fitness plans and appointment scheduling.
- Wound assessment to offer recommendations or suggest telemedicine consultations. 
