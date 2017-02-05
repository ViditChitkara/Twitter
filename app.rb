require 'sinatra'
require 'data_mapper'
set :bind,'0.0.0.0'
enable :sessions


DataMapper.setup(:default, 'sqlite:////home/vidit/alchemy/lecture4/twitter/data.db')

class User
	include DataMapper::Resource
	property :id , Serial
	property :username , String
	property :password , String
end

class Message
	include DataMapper::Resource
	property :message , String
	property :sender_id , Integer
	property :sender , String
	property :reciever , String
	property :reciever_id, Integer
	property :id , Serial
end

class Tweets
	include DataMapper::Resource
	property :id , Serial
	property :tweet_message , String
	property :user_id , Integer
	property :username , String
end

class Likes 
	include DataMapper::Resource
		property :id , Serial
	property :tweet_id , Integer
	property :user_id , Integer

end


DataMapper.finalize
User.auto_upgrade!
Message.auto_upgrade!
Tweets.auto_upgrade!
Likes.auto_upgrade!
get '/' do
	current_user=nil
	if session[:id]
		current_user=User.get(session[:id])
	else
		redirect '/login'
	end
	tweets=Tweets.all()
	likes=Likes.all()
	erb :tweets , locals: {:tweets=>tweets , :current_user=>current_user , :likes=>likes}
end

get '/login' do
	erb :login
end

get '/signup' do
	erb :signup
end

post '/login' do
	username=params[:login_username]
	password=params[:login_password]
	user=User.all(:username=>username).first
	if user
		if user.password==password
			session[:id]=user.id
			redirect '/'
		else
			redirect 'login'
		end		
	else
		redirect '/signup'
	end
end

post '/signup' do
	username=params[:signup_username]
	password=params[:signup_password]
	new_user=User.new
	new_user.username=username
	new_user.password=password
	new_user.save
	session[:id]=new_user.id
	redirect '/'
end

post '/logout' do
	session[:id]=nil
	redirect '/'
end

post '/messages' do
	messages=Message.all(:reciever_id=>session[:id])
	current_user=User.get(session[:id]).username
	erb :personalmessage , locals: {:messages=>messages,:current_user=>current_user}
end

post '/send_message' do
	message=Message.new
	message.message=params[:sent_message]
	message.sender_id=session[:id]
	message.sender=User.get(session[:id]).username
	message.reciever=params[:sent_to]
	message.reciever_id=User.all(:username=>params[:sent_to]).first.id
	message.save
	redirect '/'
end

post '/delete_account' do
	user=User.get(session[:id])
	tweets=Tweets.all(:user_id=>session[:id])
	tweets.destroy()
	user.destroy()
	session[:id]=nil
	redirect '/'
end

post '/make_tweet' do
	tweet_message=params[:tweet_message]
	new_tweet=Tweets.new
	new_tweet.tweet_message=tweet_message
	new_tweet.username=User.get(session[:id]).username
	new_tweet.user_id=session[:id]
	new_tweet.save
	redirect '/'
end

post '/delete_tweet' do
	tweet=Tweets.get(params[:delete])
	tweet.destroy()
	redirect '/'
end

get '/like/:tweet_id' do
	like=Likes.all(:tweet_id=>params[:tweet_id],:user_id=>session[:id]).first
	if !like
	like=Likes.new
	like.tweet_id=params[:tweet_id]
	like.user_id=session[:id]
	like.save
	else
	like.destroy
	end
	redirect '/'
end

post '/edit_tweet' do
	tweet=Tweets.get(params[:edit])
	erb :edit , locals: {:tweet=>tweet}
end

post '/edit' do
	tweet=Tweets.get(params[:editted_id])
	tweet.tweet_message=params[:editted]
	tweet.save
	redirect '/'
end

