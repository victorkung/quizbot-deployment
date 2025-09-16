desc "Fill the database tables with some sample data"
task({ sample_data: :environment }) do
  desc "Fill the database tables with some sample data"
  task({ sample_data: :environment }) do
    puts "Creating sample data..."

    Message.destroy_all
    Quiz.destroy_all
    User.destroy_all

    usernames = ["alice", "bob", "carol", "dave", "eve"]
    users = []
    usernames.each do |username|
      user = User.new
      user.username = username
      user.email = "#{username}@example.com"
      user.password = "appdev"
      user.save

      users.push(user)
    end

    # Define quiz topics: which user gets which topics
    quiz_topics = [
      { :user => users.at(0), :quiz_topic => "AI" },
      { :user => users.at(0), :quiz_topic => "Ruby on Rails" },
      { :user => users.at(0), :quiz_topic => "Chicago" },
      { :user => users.at(0), :quiz_topic => "Geography" },
      { :user => users.at(1), :quiz_topic => "HTTP Basics" },
      { :user => users.at(1), :quiz_topic => "HTML" },
      { :user => users.at(1), :quiz_topic => "AI" },
      { :user => users.at(2), :quiz_topic => "Geography" },
      { :user => users.at(2), :quiz_topic => "Chicago" },
      { :user => users.at(3), :quiz_topic => "Ruby on Rails" },
      { :user => users.at(3), :quiz_topic => "HTML" },
      { :user => users.at(3), :quiz_topic => "HTTP Basics" },
      { :user => users.at(4), :quiz_topic => "AI" },
      { :user => users.at(4), :quiz_topic => "Geography" },
    ]

    quiz_topics.each do |topic|
      # Create a new quiz for each topic
      topic_name = topic.fetch(:quiz_topic)
      topic_user = topic.fetch(:user)
      quiz = Quiz.create(topic: topic_name, user_id: topic_user.id)

      # Create the system message to set the context for the quiz
      system_message = Message.new
      system_message.quiz_id = quiz.id
      system_message.role = "system"
      system_message.content = "You are a #{quiz.topic} tutor. Ask the user five questions to assess their #{quiz.topic} proficiency. Start with an easy question. After each answer, increase or decrease the difficulty of the next question based on how well the user answered. In the end, provide a score between 0 and 10."
      system_message.save

      # Create the user message to start the conversation
      user_message = Message.new
      user_message.quiz_id = quiz.id
      user_message.role = "user"
      user_message.content = "Can you assess my #{quiz.topic} proficiency?"
      user_message.save

      # Create the assistant message to kick off the quiz
      assistant_message = Message.new
      assistant_message.quiz_id = quiz.id
      assistant_message.role = "assistant"

      if topic_name == "AI"
        assistant_message.content = "What does AI stand for, and can you provide a simple definition?"
      elsif topic_name == "Ruby on Rails"
        assistant_message.content = "What is Ruby on Rails, and what is its primary purpose in web development?"
      elsif topic_name == "Chicago"
        assistant_message.content = "What is a Chicago-style hot dog typically garnished with?"
      elsif topic_name == "Geography"
        assistant_message.content = "What is the capital of France?"
      elsif topic_name == "HTTP Basics"
        assistant_message.content = "What does HTTP stand for?"
      elsif topic_name == "HTML"
        assistant_message.content = "What does HTML stand for?"
      end

      assistant_message.save
    end
  end
end
