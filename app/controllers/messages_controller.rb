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
      chat.model = "o4-mini"

      # Initialize it with the correct previous_response_id
      the_quiz = the_message.quiz
      most_recent_ai_message = the_quiz.messages.order(:created_at).where({ :role => "assistant" }).last
      chat.previous_response_id = most_recent_ai_message.prev_model_response_id

      ap chat

      # Set the next user message
      chat.user(the_message.content)

      # Generate the next AI reply
      @ai_response = chat.generate!

      # Save it
      message = Message.new
      message.prev_model_response_id = chat.previous_response_id
      message.content = @ai_response
      message.role = "assistant"
      message.quiz_id = the_quiz.id
      message.save

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
