class MessagesController < ApplicationController
  def index
    matching_messages = Message.all

    @list_of_messages = matching_messages.order({ :created_at => :desc })

    render({ :template => "message_templates/index" })
  end

  def show
    the_id = params.fetch("path_id")

    matching_messages = Message.where({ :id => the_id })

    @the_message = matching_messages.at(0)

    render({ :template => "message_templates/show" })
  end

  def create
    the_message = Message.new
    the_message.quiz_id = params.fetch("query_quiz_id")
    the_message.content = params.fetch("query_content")
    the_message.role = "user"

    if the_message.valid?
      the_message.save

      # Create an AI::Chat
      chat = AI::Chat.new
      chat.model = "gpt-5-nano"

      # Initialize it with the correct previous_response_id
      the_quiz = the_message.quiz

      most_recent_ai_message = the_quiz.
        messages.
        order(:created_at).
        where({ :role => "assistant" }).
        last

      chat.previous_response_id = most_recent_ai_message.prev_model_response_id

      # Set the next user message
      chat.user(the_message.content)

      if the_quiz.messages.count >= 8
        # After the third user response (8 total messages), ask for a score using structured output

        chat.model = "gpt-5-nano"

        # Set up the schema for structured output
        chat.schema = {
          type: "object",
          properties: {
            score: {
              type: "number",
              description: "A decimal score between 0 and 10 representing the user's proficiency, where 0 is no knowledge and 10 is expert level"
            },
            explanation: {
              type: "string",
              description: "An explanation of why this score was given, and where the user can improve."
            }
          },
          required: ["score", "explanation"],
          additionalProperties: false
        }

        score_response = chat.generate!

        scoring_message = Message.new
        scoring_message.prev_model_response_id = chat.previous_response_id
        scoring_message.content = score_response.fetch(:explanation)
        scoring_message.role = "assistant"
        scoring_message.quiz_id = the_quiz.id
        scoring_message.save!

        # Save the score to the quiz
        the_quiz.score = score_response.fetch(:score)
        the_quiz.save!
      else
        # Before the third question & response, generate the next AI reply normally
        @ai_response = chat.generate!

        # Save it
        message = Message.new
        message.prev_model_response_id = chat.previous_response_id
        message.content = @ai_response
        message.role = "assistant"
        message.quiz_id = the_quiz.id
        message.save
      end

      redirect_to("/quizzes/#{the_message.quiz_id}", { :notice => "Message created successfully." })
    else
      redirect_to("/quizzes/#{the_message.quiz_id}", { :alert => the_message.errors.full_messages.to_sentence })
    end
  end

  def update
    the_id = params.fetch("path_id")
    the_message = Message.where({ :id => the_id }).at(0)

    the_message.quiz_id = params.fetch("query_quiz_id")
    the_message.content = params.fetch("query_content")
    the_message.role = params.fetch("query_role")

    if the_message.valid?
      the_message.save
      redirect_to("/messages/#{the_message.id}", { :notice => "Message updated successfully." } )
    else
      redirect_to("/messages/#{the_message.id}", { :alert => the_message.errors.full_messages.to_sentence })
    end
  end

  def destroy
    the_id = params.fetch("path_id")
    the_message = Message.where({ :id => the_id }).at(0)

    the_message.destroy

    redirect_to("/messages", { :notice => "Message deleted successfully." } )
  end
end
