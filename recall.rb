# myapp.rb
require 'sinatra'
require 'sinatra/flash'
require 'data_mapper'
require 'sinatra/reloader' if development?
#require 'rack-flash'
#require 'sinatra/redirect_with_flash'

SITE_TITLE = "Recall"
SITE_DESCRIPTION = "'cause you're too busy to remember"

enable :sessions
#use Rack::Flash, :sweep => true
#enable :flash
#register Sinatra::Flash

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/recall.db")
 
class Note
  include DataMapper::Resource
  property :id, Serial
  property :content, Text, :required => true
  property :complete, Boolean, :required => true, :default => false
  property :created_at, DateTime
  property :updated_at, DateTime
end
 
DataMapper.finalize.auto_upgrade!

helpers do
    include Rack::Utils
    alias_method :h, :escape_html
end

get '/' do
  @notes = Note.all :order => :id.desc
  @title = 'All Notes'
  if @notes.empty?
    flash.now[:notice] = 'No notes found. Add your first below.'
  end  
  erb :home
end

post '/' do
  n = Note.new
  n.content = params[:content]
  n.created_at = Time.now
  n.updated_at = Time.now
  if n.save
    flash.next[:notice] = 'Note created successfully'
  else
    flash.next[:notice] = 'Failed to save note'
   end
   redirect '/'
end

# RSS route needs to be prior to get id route
get '/rss.xml' do
    @notes = Note.all :order => :id.desc
    builder :rss
end

# edit a note - get route
get '/:id' do
  @note = Note.get params[:id]
  @title = "Edit note ##{params[:id]}"
  if @note
    erb :edit
  else
    flash.next[:error] = "Can't find that note"
    redirect '/'
  end     
end

# edit a note - put route
put '/:id' do
  n = Note.get params[:id]
  unless n
    flash.next[:error] = "Can't find that note"
    redirect '/'
  end
  n.content = params[:content]
  n.complete = params[:complete] ? 1 : 0
  n.updated_at = Time.now
  if n.save
    flash.next[:notice] = 'Note updated successfully'
  else
    flash.next[:error] = 'Error updating notice'
  end 
  redirect '/'
end

# edit a note's complete indicator from root path - get route
get '/:id/complete' do
  n = Note.get params[:id]
  unless n
    flash.next[:error] = "Can't find that note"
    redirect '/'
  end  
  n.complete = n.complete ? 0 : 1 # flip it
  n.updated_at = Time.now
  if n.save
    flash.next[:notice] = 'Note marked as complete'
  else
    flash.next[:error] = 'Error marking note as complete'
  end 
  redirect '/'
end

# delete a note - get route
get '/:id/delete' do
  @note = Note.get params[:id]
  @title = "Confirm deletion of note ##{params[:id]}"
  if @note
    erb :delete
  else
    flash.next[:error] = "Can't find that note"
    redirect '/'
  end
end

# delete a note - delete route
delete '/:id' do
  n = Note.get params[:id]
  if n.destroy
    flash.next[:notice] = 'Note deleted successfully'
  else
    flash.next[:error] = "Can't find that note"
  end
  redirect '/'
end