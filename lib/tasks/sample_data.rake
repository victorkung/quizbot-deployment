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
  end
end
