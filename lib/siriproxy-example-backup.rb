# -*- encoding : utf-8 -*-
require 'cora'
require 'siri_objects'
require 'pp'

#######
# This is a "hello world" style plugin. It simply intercepts the phrase "test siri proxy" and responds
# with a message about the proxy being up and running (along with a couple other core features). This 
# is good base code for other plugins.
# 
# Remember to add other plugins to the "config.yml" file if you create them!
######

#Note about returns from filters:
# - Return false to stop the object from being forwarded
# - Return a Hash to substitute or update the object
# - Return nil (or anything not a Hash or false) to have the object forwarded (along with any 
#    modifications made to it)

class SiriProxy::Plugin::Example < SiriProxy::Plugin
  def initialize(config)
    #if you have custom configuration options, process them here!
  end

  #get the user's location and display it in the logs
  #filters are still in their early stages. Their interface may be modified
  filter "SetRequestOrigin", direction: :from_iphone do |object|
    puts "[Info - User Location] lat: #{object["properties"]["latitude"]}, long: #{object["properties"]["longitude"]}"       
  end 
    
  #Essential for server status
  listen_for /Proxy Info/i do
    @keysavailable=$keyDao.listkeys().count
    if @keysavailable==1
      say "Es ist ein Key verfuegbar" #say something to the user!    
      request_completed #always complete your request! Otherwise the phone will "spin" at the user!
    elsif @keysavailable>0    
      say "There are #{@keysavailable} keys available" #say something to the user!    
      request_completed #always complete your request! Otherwise the phone will "spin" at the user!
    else
      say "All keys are overloaded!" #say something to the user!    
      request_completed #always complete your request! Otherwise the phone will "spin" at the user!
    end
  end
  
  listen_for /Wie viele Aktive Verbindungen/i do
    $conf.active_connections = EM.connection_count 
    @activeconnections=$conf.active_connections
    if @activeconnections>0
      say " #{@activeconnections} Aktive Verbindungen" #say something to the user!    
      request_completed #always complete your request! Otherwise the phone will "spin" at the user!
    else
      say "Something went wrong!" #say something to the user!    
      request_completed #always complete your request! Otherwise the phone will "spin" at the user!
    end
  end
  #end of server status monitor  
  
  listen_for /test siri proxy/i do
    say "Siri Proxy ist Online! Theo du brauchst dir keine Sorgen machen!" #say something to the user!
    
    request_completed #always complete your request! Otherwise the phone will "spin" at the user!
  end
  
  #Demonstrate that you can have Siri say one thing and write another"!
  listen_for /you don't say/i do
    say "Sometimes I don't write what I say", spoken: "Sometimes I don't say what I write"
  end 

  #demonstrate state change
  listen_for /siri proxy test state/i do
    set_state :some_state #set a state... this is useful when you want to change how you respond after certain conditions are met!
    say "I set the state, try saying 'confirm state change'"
    
    request_completed #always complete your request! Otherwise the phone will "spin" at the user!
  end
  
  listen_for /confirm state change/i, within_state: :some_state do #this only gets processed if you're within the :some_state state!
    say "State change works fine!"
    set_state nil #clear out the state!
    
    request_completed #always complete your request! Otherwise the phone will "spin" at the user!
  end
  
  #demonstrate asking a question
  listen_for /siri proxy test question/i do
    response = ask "Is this thing working?" #ask the user for something
    
    if(response =~ /yes/i) #process their response
      say "Great!" 
    else
      say "You could have just said 'yes'!"
    end
    
    request_completed #always complete your request! Otherwise the phone will "spin" at the user!
  end
  
  #demonstrate capturing data from the user (e.x. "Siri proxy number 15")
  listen_for /siri proxy number ([0-9,]*[0-9])/i do |number|
    say "Detected number: #{number}"
    
    request_completed #always complete your request! Otherwise the phone will "spin" at the user!
  end
  
  #demonstrate injection of more complex objects without shortcut methods.
  listen_for /test map/i do
    add_views = SiriAddViews.new
    add_views.make_root(last_ref_id)
    map_snippet = SiriMapItemSnippet.new
    map_snippet.items << SiriMapItem.new
    utterance = SiriAssistantUtteranceView.new("Testing map injection!")
    add_views.views << utterance
    add_views.views << map_snippet
    
    #you can also do "send_object object, target: :guzzoni" in order to send an object to guzzoni
    send_object add_views #send_object takes a hash or a SiriObject object
    
    request_completed #always complete your request! Otherwise the phone will "spin" at the user!
  end
end
