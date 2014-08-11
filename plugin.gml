/**
 * Chat/console server sent plugin, made by Lorgan3.
 * Bugs fixed by arctic
*/

/*CHANGES*/
//rcon beta(mostly dosnt work)
//logging
//broadcast command

/*TODO*/
//make rcon work(ehhhh)
//fix voting even more(shit i think it already works correctly)
//make block actually work
//finish logging(done)

//define global variables
global.chatSendBuffer = buffer_create();
global.chatPacketID = argument1;
global.consoleFont = font_add("Lucida Console",8,0,0,32,127);
global.chatEmotes = sprite_add(argument0+"/ChatEmotes.png",9,1,0,0,0);
global.mikuS = sprite_add(argument0+"/MikuS.png",9,0,0,16,16);


//quotes from steve
//variable to make it easy to add more quotes
global.totalQuotes = 19;
global.quoteGen[0]=('75% of stair accidents happen on stairs!');
global.quoteGen[1]=('How do you know a Black used your computer?');
global.quoteGen[2]=("That's what.* -She");
global.quoteGen[3]=('I miss my umbilical cord. I grew up attached to it.');
global.quoteGen[4]=('Sperm jokes come in unexpected.');
global.quoteGen[5]=("The buggy draw event actually isn't arctic's fault");
global.quoteGen[6]=("404: Punny quote not found")
global.quoteGen[7]=("Not widescreen tested");
global.quoteGen[8]=("Help, I'm stuck in a randomly-generated quote factory!");
global.quoteGen[9]=("Worth more than miku");
global.quoteGen[10]=("Don't have a event clearing fetish");
global.quoteGen[11]=("I play nice with DSM");
global.quoteGen[12]=("there was a medic going z6");
global.quoteGen[13]=("I made cookies");
global.quoteGen[14]=("Bow down before the itemkings");
global.quoteGen[15]=("z6 z6 z6 z6 z6 z6 z6 z6 z6 z6 z6")
global.quoteGen[16]=("global.quoteGen[16]");
global.quoteGen[17]=("FYI DORITOS ARE BETTER THAN SUNCHIPS");
global.quoteGen[18]=("Alex stop being a spammy mofo");
global.quoteGen[19]=("GUYS TYPE /SWAG");

//Define console commands
//other plugins may have created the map before the plugin is executed
if !variable_global_exists("commandMap") {  //all server commands go here
    global.commandMap = ds_map_create();
}
if !variable_global_exists("voteCommandMap") {  //additional code that gets executed after voting
    global.voteCommandMap = ds_map_create();
}
if !variable_global_exists("clientComandMap") {   //all client commands go here
    global.clientCommandMap = ds_map_create();
}
if !variable_global_exists("helpMap") { //a string on how to use a specific command
    global.helpMap = ds_map_create();
}

//import command maps
execute_file(argument0+"/commands.gml");

//build a list of votable maps
global.votableMaps = ds_list_create();
if file_exists("VotableMaps.txt") {
    //steal code from game_init :3
    var fileHandle, i, mapname;
    fileHandle = file_text_open_read("VotableMaps.txt");
    for(i = 1; !file_text_eof(fileHandle); i += 1) {
        mapname = file_text_read_string(fileHandle);
        // remove leading whitespace from the string
        while(string_char_at(mapname, 0) == " " || string_char_at(mapname, 0) == chr(9)) { // while it starts with a space or tab
          mapname = string_delete(mapname, 0, 1); // delete that space or tab
        }
        if(mapname != "" && string_char_at(mapname, 0) != "#") { // if it's not blank and it's not a comment (starting with #)
            ds_list_add(global.votableMaps, mapname);
        }
        file_text_readln(fileHandle);
    }
    file_text_close(fileHandle);
} else {
    var file;
    for (file = file_find_first(working_directory+'\Maps\*.png', 0); file != ''; file = file_find_next()) {
        ds_list_add(global.votableMaps, string_lower(string_copy(file,0,string_length(file)-4)));
    }
    //add the default maps too... (is there a better way to do this?)
    ds_list_add(global.votableMaps,'ctf_truefort');
    ds_list_add(global.votableMaps,'ctf_2dfort');
    ds_list_add(global.votableMaps,'ctf_conflict');
    ds_list_add(global.votableMaps,'ctf_classicwell');
    ds_list_add(global.votableMaps,'ctf_waterway');
    ds_list_add(global.votableMaps,'ctf_orange');
    ds_list_add(global.votableMaps,'cp_dirtbowl');
    ds_list_add(global.votableMaps,'cp_egypt');
    ds_list_add(global.votableMaps,'arena_lumberyard');
    ds_list_add(global.votableMaps,'arena_montane');
    ds_list_add(global.votableMaps,'gen_destroy');
    ds_list_add(global.votableMaps,'koth_valley');
    ds_list_add(global.votableMaps,'koth_corinth');
    ds_list_add(global.votableMaps,'koth_harvest');
    ds_list_add(global.votableMaps,'dkoth_atalia');
    ds_list_add(global.votableMaps,'dkoth_sixties');
}

ini_open("gg2.ini");
global.chatGlobal = ini_read_real("Plugins","chat_global",ord('Y'));
global.chatTeam = ini_read_real("Plugins","chat_team",ord('U'));
global.chatToggle = ini_read_real("Plugins","chat_toggle",ord('T'));
global.parseEmotes = ini_read_real("Plugins","chat_parse_emotes",1);
global.playerInfo = ini_read_real("Plugins","chat_player_info",1);
global.rconKey = ini_read_string("Plugins","chat_rconKey","");
global.rconHash = md5(global.rconKey)
global.logChat = ini_read_real("Plugins","chat_logging",1);

//add some text to the window
global.chatLog = ds_list_create();
ds_list_add(global.chatLog,"OArctic's chat extended v1.2.1 - press T to show/hide,");
ds_list_add(global.chatLog,"OAnd now for something totally different");
ds_list_add(global.chatLog,"O"+string(global.quoteGen[irandom(global.totalQuotes)]));
ds_list_add(global.chatLog,"OY to chat and U to teamchat.");
ds_list_add(global.chatLog,"OType '/help' for console commands.");

global.chatTime = ds_list_create();
ds_list_add(global.chatTime,current_time);
ds_list_add(global.chatTime,current_time);
ds_list_add(global.chatTime,current_time);
ds_list_add(global.chatTime,current_time);

global.blockedCommands = ds_list_create();
var i, tmp;
tmp = ds_map_find_first(global.commandMap);
if ini_read_real("Plugins",'chat_'+string(tmp),0) == 1 ds_list_add(global.blockedCommands,tmp);
for(i=1;i<ds_map_size(global.commandMap)-1;i+=1) {
    tmp= string(ds_map_find_next(global.commandMap,tmp));
    if ini_read_real("Plugins",'chat_'+tmp,0) == 1 ds_list_add(global.blockedCommands,tmp);
}

ini_close();

//make folder for logs
if (global.logChat == 1)
{
    if (!directory_exists(working_directory + "\ServerPluginsData\Logs")) {
        directory_create(working_directory + "\ServerPluginsData\Logs");
    }
}

if (!directory_exists(working_directory + "\ServerPluginsData\gml")) {
        directory_create(working_directory + "\ServerPluginsData\gml");
    }

//make a new menu for plugin options
if !variable_global_exists("chatOptions") {
    global.chatOptions = object_add();
    object_set_parent(global.chatOptions,OptionsController);  
    object_set_depth(global.chatOptions,-130000); 
    object_event_add(global.chatOptions,ev_create,0,'   
        menu_create(40, 140, 300, 200, 30);
    
        if room != Options {
            menu_setdimmed();
        }
    
        menu_addback("Back", "
            instance_destroy();
            if(room == Options)
                instance_create(0,0,MainMenuController);
            else
                instance_create(0,0,InGameMenuController);
        ");
    ');
    
    object_event_add(InGameMenuController,ev_create,0,'
        menu_addlink("Chat Options", "
            instance_destroy();
            instance_create(0,0,global.chatOptions);
        ");
    ');
} 

object_event_add(global.chatOptions,ev_create,0,'
    menu_addedit_key("Global chat","global.chatGlobal","");
    menu_addedit_key("Team chat","global.chatTeam","");
    menu_addedit_key("Toggle chatwindow","global.chatToggle","");
    menu_addedit_boolean("Parse chat emotes:", "global.parseEmotes", "");
    menu_addedit_boolean("Display player info:", "global.playerInfo", "");
    menu_addedit_boolean("Save Chat to File:", "global.logChat","");
');

object_event_add(global.chatOptions,ev_destroy,0,'
    ini_open("gg2.ini");
    ini_write_real("Plugins","chat_global",global.chatGlobal);
    ini_write_real("Plugins","chat_team",global.chatTeam);
    ini_write_real("Plugins","chat_toggle",global.chatToggle);
    ini_write_real("Plugins","chat_parse_emotes",global.parseEmotes);
    ini_write_real("Plugins","chat_player_info",global.playerInfo);
    ini_write_real("Plugins","chat_logging",global.logChat);
    ini_write_real("Plugins","chat_rconKey",global.rconKey);
    ini_close();
');

//create the new object
object_event_add(PlayerControl,ev_step,ev_step_begin,'if !instance_exists(global.chatWindow) instance_create(0,0,global.chatWindow);');

//to prevent gay errors
object_event_add(Player,ev_create,0,'
        hasChat = false;
        nameBkp = "";
        hasMiku = -1;
        lastChatTime = 0;
        chatCount = 0;
        canVote = false;
        mute = false;
        mayVote = true;
        lastVoteCall = current_time-2000*60;
        muteChecked = false;
        //isRcon = -1;
');

//because server-sent plugins do weird things on startup + name change detection
object_event_add(Player,ev_step,ev_step_begin,'
    //this only gets executed for host.
    if !variable_local_exists("hasChat") {        
        hasChat = false;
        nameBkp = "";
        hasMiku = -1;
        lastChatTime = 0;
        chatCount = 0;
        canVote = false;
        mute = false;
        mayVote = true;
        lastVoteCall = current_time-2000*60;
        muteChecked = false;
        //isRcon = -1;
    }
    
    if global.isHost {
        if !variable_local_exists("checkIfKicked") {
            checkIfKicked = true;
            if instance_exists("global.chatWindow") {
	               if ds_list_find_index(global.chatWindow.chatKicklist,socket_remote_ip(socket)) != -1 kicked = true;
            }
        }
        
        if name != nameBkp {
            var count, length;
            count = 0;
            length = min(18,string_length(name));
            
            if name == "" {
                name = "Player";
                count = 1;
            }
            //change the new name so that no players have the same name.
            with(Player) {
                if string_lower(string_copy(other.name,0,length)) == string_lower(string_copy(name,0,length)) count += 1;
            }
            
            if count > 1 {  //there are other people with the same name
                name = string_copy(name,0,length)+string(count);
                write_ubyte(global.sendBuffer, PLAYER_CHANGENAME);
                write_ubyte(global.sendBuffer, ds_list_find_index(global.players,id));
                write_ubyte(global.sendBuffer, string_length(name));
                write_string(global.sendBuffer, name);
            }
            
            if nameBkp == "" {
                nameBkp = name;
                exit;
            }

            if hasChat || global.myself == id {
                with(global.chatWindow) {
                    _message = "O"+other.nameBkp+" has changed their name to "+other.name+".";
                    _team = 0;
                    target = Player;
                    playerId = 254;
                    event_user(2); //tell everyone someone changed names
                    event_user(4); //add to own chat
                }
                nameBkp = name;
            }
        }
    }
');

//draw miku :3
object_event_add(Character,ev_draw,0,"
    if player.hasMiku {
        if !variable_local_exists('mikuX') {
            mikuX = x;
            mikuY = y;
            floatDir = 0.5;
            floatOffset = 0;
            mikuFrame = 1;
            effect_create_above(ef_firework,mikuX,mikuY,1,c_ltgray);
        }
        mikuX = median(x-40,mikuX,x+40);
        mikuY = median(y-40,mikuY,y);
        floatOffset += floatDir;
        if abs(floatOffset) > 15 floatDir *= -1;
        var dir;
        if mikuX > x dir = -1;
        else dir = 1;
        
        if cloak {
            if mikuFrame != 7 effect_create_above(ef_smoke,mikuX,mikuY,1,c_ltgray);
            mikuFrame = 7;
        } else if !cloak && mikuFrame == 7 {
            effect_create_above(ef_smoke,mikuX,mikuY,1,c_ltgray);
            mikuFrame = 1;
        } else if abs(hspeed) > 6 mikuFrame = 4;
        else if moveStatus == 1 mikuFrame = 4;
        else mikuFrame = 1;
        
        if stabbing || ubered draw_sprite_ext(global.mikuS,mikuFrame+floor(animationImage),mikuX,mikuY+floatOffset,dir*2,2,0,c_white,1);
        else if !invisible && !(cloak && player.team != global.myself.team) draw_sprite_ext(global.mikuS,mikuFrame+floor(animationImage),mikuX,mikuY+floatOffset,dir*2,2,0,c_white,image_alpha);
    }
");

//send a message when someone leaves
object_event_add(Player,ev_destroy,0,'
    if hasChat && global.isHost {
        with(global.chatWindow) {
            _message = "O"+other.name+" has left the game.";
            _team = 0;

            playerId = 254;
            event_user(2); //tell everyone someone left
            event_user(4); //add to own chat
        }
    }
');

//send a message to the server to tell that we have the chat plugin
object_event_add(PlayerControl,ev_create,0,"
    if !global.isHost {
        write_ubyte(global.chatSendBuffer,0); //hello
        PluginPacketSend(global.chatPacketID,global.chatSendBuffer);
        buffer_clear(global.chatSendBuffer);
    }
");

//add the new object, set depth and set persistent
if !variable_global_exists('chatWindow') global.chatWindow = object_add(); //Other plugins may have run before and already injected code.
object_set_depth(global.chatWindow, -110002);
object_set_persistent(global.chatWindow,false);

//initialize
object_event_add(global.chatWindow,ev_create,0,"
    open = false;
    hidden = true;
    team = false;
    offset = 0;
    image_speed = 0;
    
    votePlayer = noone;
    votes=ds_list_create();
    
    arguments = ds_list_create();
    options = ds_list_create();
    voteCommand = ds_list_create();
    
    target = Player;
    playerId = 0;
    selectedmap = false;
    
    fakeMaprotation = ds_list_create(); //for mapvoting
    oldRotation = global.map_rotation;
    oldMapIndex = -1;
    global.currentMapIndex = -1;
    
    global.chatBanlist = ds_list_create();
    //global.rconlist = ds_list_create();
    chatKicklist = ds_list_create();
    global.serverBanList = ds_list_create();
    rainbow = 0;
");

//alarm 0 happens when a vote ends
object_event_add(global.chatWindow,ev_alarm,0,"
    with(Player) mayVote = true;    //reset this var after the vote is over
    if global.isHost && votePlayer == noone {
        if ds_list_size(voteCommand) > 0 {
            execute_string(ds_map_find_value(global.voteCommandMap,ds_list_find_value(voteCommand,0)),voteCommand,votes);
        } else with(global.voter) instance_destroy();
    }
    ds_list_clear(voteCommand);
    ds_list_clear(votes);
    ds_list_clear(options);
    votePlayer = noone;
");

//All main stuff happens here
object_event_add(global.chatWindow,ev_step,ev_step_end,'
    x = view_xview[0]+7;
    y = view_yview[0]+340;
    if (!instance_exists(InGameMenuController) && !instance_exists(OptionsController) && !instance_exists(ControlsController) && !instance_exists(HUDOptionsController)) || instance_exists(global.cheatycheat) {
        if keyboard_check_pressed(global.chatToggle) && !open {
            if !open hidden = !hidden;
        } else if keyboard_check_pressed(global.chatGlobal) && !open {
            open = true;
            keyboard_string="";
            team = false;
            instance_create(0,0,global.cheatycheat);
        }  else if keyboard_check_pressed(global.chatTeam) && global.myself.team != TEAM_SPECTATOR && !open {
            open = true;
            keyboard_string="";
            team = true;
            instance_create(0,0,global.cheatycheat);
        } else if open && keyboard_check_pressed(vk_enter) {
            with(global.cheatycheat) instance_destroy();
            if keyboard_string != "" {
                _message = keyboard_string;
                if global.isHost {
                    _player = global.myself;
                    if team == true _team = global.myself.team+1;
                    else _team = 0;
                    event_user(9);
                } else {
                    _team = team;
                    if string_char_at(_message,1) == "/" {
                        event_user(12);
                        if ds_map_exists(global.clientCommandMap,string_lower(ds_list_find_value(arguments,0)))  execute_string(ds_map_find_value(global.clientCommandMap,string_lower(ds_list_find_value(arguments,0))),arguments);
                        else event_user(3);
                    } else event_user(3); //send a message as a client
                }
                
                keyboard_string="";
            }
            open = false;
            team = false;
        }
    }
    
    if open {        
        image_index = 1;
        if (keyboard_check_pressed(vk_up) or mouse_wheel_up()) && ds_list_size(global.chatLog) > 9 offset = min(ds_list_size(global.chatLog)-10,offset+1);
        else if keyboard_check_pressed(vk_down) or mouse_wheel_down() offset = max(0,offset-1);
    } else image_index = 0;
    
    if global.isHost {
        event_user(0); //forward messages as a host
    } else event_user(6); //read messages as a client
    
    
    if keyboard_check_direct(vk_control) 
    { 
        if keyboard_check_pressed(ord("V")) 
            keyboard_string += clipboard_get_text();
    }
');

//draw
object_event_add(global.chatWindow,ev_draw,0,"
    var xoffset, yoffset, xsize, ysize, index;
    
    xsize = 380;
    ysize = 180;
    
    draw_set_valign(fa_top);
    draw_set_halign(fa_left);
    draw_set_font(global.consoleFont);
    
    if !hidden || open {
        draw_set_color(make_color_rgb(61,61,61));
        draw_set_alpha(0.8);
        draw_rectangle(x,y,x+380,y+155,false);
        if open draw_rectangle(x,y+160,x+380,y+180,false);
        
        draw_set_color(c_black);
        draw_set_alpha(1);
        draw_rectangle(x,y,x+380,y+155,true);
        if open draw_rectangle(x,y+160,x+380,y+180,true);
    } else draw_set_alpha(1);
    draw_set_color(c_white);
    
    //prevent too long strings
    if open {
        keyboard_string = string_copy(keyboard_string,1,230); //limit messages
        
        //make that the text doesnt go outside the chatwindow
        if string_length(keyboard_string)-53 > 0 index  = string_length(keyboard_string)-52;
        else index = 0;
        chatmessage = string_copy(keyboard_string,index,53);
        if team == 1 {
            if global.myself.team == TEAM_BLUE message='B';
            else message = 'R';
            event_user(5);
        }
        draw_text(x + 3, y+ysize-15, chatmessage);
    }
    
    // The drawing of the text
    var amount;
    if !hidden || open amount = min(ds_list_size(global.chatLog),10);
    else {
        for(i=ds_list_size(global.chatLog)-1;i>=ds_list_size(global.chatLog)-10 && i>=0;i-=1) {
            if current_time-ds_list_find_value(global.chatTime,i) > 10000 break;
        }
        amount = ds_list_size(global.chatLog)-1-i;
    }
    for(i=0;i<amount;i+=1) {
        message = ds_list_find_value(global.chatLog, ds_list_size(global.chatLog)-amount+i-offset);
        prefix = '';
        pos = string_pos('#',message);
        if pos != 0 {
            event_user(5); //read the color code
            prefix = string_copy(message,2,pos-1);
            draw_text(x+10, y+ysize-35-13*(amount-i),prefix);
            message = string_copy(message,pos+1,255);
        }
        event_user(5); //read the next color code
        message = string_copy(message,2,255);
        
        var zOffset, xOffset, part, bubble;
        xOffset = x+10+string_width(prefix);
        if global.parseEmotes {
            zOffset = string_pos('z',message);
            while(zOffset != 0) {
                bubble = '0';
                if string_char_at(message,zOffset-1) == ' ' || zOffset = 1 {
                    if string_char_at(message,zOffset+2) == ' ' || zOffset+2 > string_length(message) {
                        if string_char_at(message,zOffset+1) > '0' && string_char_at(message,zOffset+1) <= '9' {
                            bubble = string_char_at(message,zOffset+1);
                            part = string_copy(message,1,max(0,zOffset-2));
                            message = string_copy(message,zOffset+2,string_length(message));
                            
                            draw_text(xOffset, y+ysize-35-13*(amount-i),part);
                            xOffset += string_width(part);
                            draw_sprite(global.chatEmotes,real(bubble)-1,xOffset+7, y+ysize-35-13*(amount-i));
                            xOffset+=20;
                        }
                    }
                }
                if bubble == '0' {
                    part = string_copy(message,1,zOffset);
                    message = string_copy(message,zOffset+1,string_length(message));  
                    draw_text(xOffset, y+ysize-35-13*(amount-i),part);
                    xOffset += string_width(part); 
                }
                zOffset = string_pos('z',message);
            }
        }
        draw_text(xOffset, y+ysize-35-13*(amount-i),message);       
    }

    
    draw_set_font(global.gg2Font);
");



//Use some events as scripts
//event0 : process input as a host
object_event_add(global.chatWindow,ev_other,ev_user0,'
    while(PluginPacketGetBuffer(global.chatPacketID) != -1) {
        chatReceiveBuffer = PluginPacketGetBuffer(global.chatPacketID);
        _player = PluginPacketGetPlayer(global.chatPacketID);
        if _player == -1 || !instance_exists(_player) break;
        switch(read_ubyte(chatReceiveBuffer)) {
            case 0: //hello
                if ds_list_find_index(global.chatBanlist,socket_remote_ip(_player.socket)) == -1 {  //ignore muted players
                    _player.hasChat = true;
                    _player.nameBkp = _player.name;
                    _message = "O"+_player.name+" has joined chat!";
                    _team = 0;
                    target = Player;
                    playerId = 254;
                    event_user(2); //tell everyone someone joined chat
                    event_user(4); //add to own chat
                    
                    //sync miku :3
                    with(Player) {
                        if hasMiku {
                            write_ubyte(global.chatSendBuffer,202);
                            write_ubyte(global.chatSendBuffer,ds_list_find_index(global.players,id));
                        }
                    }
                    if buffer_size(global.chatSendBuffer) > 1 {
                        PluginPacketSendTo(global.chatPacketID,global.chatSendBuffer, _player);
                        buffer_clear(global.chatSendBuffer);
                    }
                    //rcons
                    /*
                    if ds_list_find_index(global.rconlist,socket_remote_ip(_player.socket)) == -1 
                    {
                        _player.isRcon = true;
                    }*/
                    
                    //sync votes if needed
                    with(global.voter) {
                        if win == -1 {
                            write_ubyte(global.chatSendBuffer,204);
                            write_ubyte(global.chatSendBuffer,min(255,string_length(question)));
                            write_string(global.chatSendBuffer,string_copy(question,0,255));
                            write_ubyte(global.chatSendBuffer,ds_list_size(options));
                            
                            var i;
                            for(i=0;i<ds_list_size(options);i+=1) {
                                write_ubyte(global.chatSendBuffer,min(255,string_length(ds_list_find_value(options,i))));
                                write_string(global.chatSendBuffer,string_copy(ds_list_find_value(options,i),0,255));
                            }
                            
                            write_ubyte(global.chatSendBuffer,ceil(alarm[0]/30));
                            
                            for(i=0;i<ds_list_size(options);i+=1) {
                                    write_ubyte(global.chatSendBuffer,optionVotes[i]);
                            }
                            
                            with(other._player) {
                                canVote = true;
                                PluginPacketSendTo(global.chatPacketID,global.chatSendBuffer, id);
                            }
                            buffer_clear(global.chatSendBuffer);
                        }
                    }
                }
                else
                {
                    _player.hasChat = false;
                }
            break;
            case 1: //global chat
                if _player.hasChat {
                    _team = 0;
                    _len = read_ubyte(chatReceiveBuffer);
                    _message = read_string(chatReceiveBuffer,_len);
                    event_user(9);
                    event_user(7); //prevent spamming
                }
            break;
            case 2: //team chat
                if _player.team != TEAM_SPECTATOR && _player.hasChat {
                    _team = 1+_player.team;
                    _len = read_ubyte(chatReceiveBuffer);
                    _message = read_string(chatReceiveBuffer,_len);
                    target = Player;
                    playerId = ds_list_find_index(global.players,_player);
                    event_user(2); //send
                    if global.myself.team == TEAM_SPECTATOR || _team == global.myself.team+1 event_user(4); //add to chatwindow
                    event_user(7); //prevent spamming
                }
            break;
            case 3: //vote reply
                vote = read_ubyte(chatReceiveBuffer);
                if _player.canVote && _player.mayVote {
                    _player.canVote = false;
                    if vote <= 9 event_user(8); //handle voting
                }
            break;
        }
        
        buffer_clear(chatReceiveBuffer);
        PluginPacketPop(global.chatPacketID);
    }
');

//event1 : process a message as host
object_event_add(global.chatWindow,ev_other,ev_user1,'
    if string_char_at(_message,1) == "/me" {
        _message = string_replace_all(_message,"/me"," ");
        _message = "W *"+_player.name+_message;
    } else {
        _message = string_replace_all(_message,"#","\#");
        if _player.team == TEAM_RED _color = "R";
        else if _player.team == TEAM_BLUE _color = "B";
        else _color = "W";
        if _team == 0 {
            if _player.id == ds_list_find_value(global.players,0) _message = _color+_player.name+": #O"+_message;
            else if _player.hasMiku {_message = _color+_player.name+": #A"+_message};
            //else if _player.isRcon == true {_message = _color+_player.name+": #Y"+_message};
            else _message = _color+_player.name+": #W"+_message;
        } else {
            _message = _color+_player.name+": "+_message;
        }
    }
');

//event2 : send a message as host
object_event_add(global.chatWindow,ev_other,ev_user2,"
    var _message2;
    _message2 = _message;
    while _message2 != '' {
        write_ubyte(global.chatSendBuffer,playerId);
        if playerId < 200 write_ubyte(global.chatSendBuffer,_team);
        write_ubyte(global.chatSendBuffer,min(255,string_length(_message2)));
        write_string(global.chatSendBuffer,string_copy(_message2,0,255));
        _message2 = string_copy(_message,255,string_length(_message));
        with(target) {
            if hasChat = true {
                if other._team > 0 && team == other._team-1 || other._team == 0 {
                    PluginPacketSendTo(global.chatPacketID,global.chatSendBuffer, id);
                }
            }
        }
        buffer_clear(global.chatSendBuffer);
    }
");
    
//event3 : send a message as a client
object_event_add(global.chatWindow,ev_other,ev_user3,'
    write_ubyte(global.chatSendBuffer,_team+1);
    write_ubyte(global.chatSendBuffer,min(255,string_length(_message)));
    write_string(global.chatSendBuffer,string_copy(_message,0,255));
    PluginPacketSend(global.chatPacketID,global.chatSendBuffer);
    buffer_clear(global.chatSendBuffer);
');
    
//event4 : add messages to the chatwindow
object_event_add(global.chatWindow,ev_other,ev_user4,'
    //make the window display the new message 
    var muted;
    muted = false; 
    if playerId < 200 { 
        event_user(1);
        muted = (ds_list_find_value(global.players,playerId)).mute;
    } else if playerId == 254 && !global.playerInfo muted = true;
    
    if !muted {
        while(string_length(_message) != 0) {
            ds_list_add(global.chatTime,current_time);
            if string_length(_message) > 53 {
               ds_list_add(global.chatLog,string_copy(_message,1,53));
               pos = string_pos("#",_message);
               if pos == 0 color = string_copy(_message,1,1);
               else color = string_copy(_message,pos+1,1);
               _message = color+string_copy(_message,54,255);
            } else {
               ds_list_add(global.chatLog,string_copy(_message,1,53));
               _message = "";
            }
        }
    }
');

//event5 : read the color code
object_event_add(global.chatWindow,ev_other,ev_user5,'
    randColor = make_color_rgb(irandom(255),irandom(255),irandom(255))
    switch(string_copy(message,1,1)) {
        case "R":
            if (rainbow == 1)
                draw_set_color(randColor);
            else
                draw_set_color(make_color_rgb(237,61,61));
            break;
        case "B":
            if (rainbow == 1)
                draw_set_color(randColor);
            else
                draw_set_color(make_color_rgb(61,135,218));
            break
        case "O":
            if (rainbow == 1)
                draw_set_color(randColor);
            else
                draw_set_color(c_orange);
            break;
        case "A":
            if (rainbow == 1)
                draw_set_color(randColor);
            else
                draw_set_color(c_aqua);
            break;
        default: 
        if (rainbow == 1)
            draw_set_color(randColor);
        else
            draw_set_color(c_white);
    }
');

//event6 : read messages as a client
object_event_add(global.chatWindow,ev_other,ev_user6,'
    while(PluginPacketGetBuffer(global.chatPacketID) != -1) {
        chatReceiveBuffer = PluginPacketGetBuffer(global.chatPacketID);
        playerId = read_ubyte(chatReceiveBuffer);
        if playerId < 200 {
            _team = read_ubyte(chatReceiveBuffer);
            _player = ds_list_find_value(global.players,playerId);
            _message = read_string(chatReceiveBuffer,read_ubyte(chatReceiveBuffer));
            event_user(4); //add to chatwindow
        } else if playerId == 200 {
            with(global.voter) instance_destroy();
            instance_create(0,0,global.voter);
            with(global.voter) {
                question = read_string(other.chatReceiveBuffer,read_ubyte(other.chatReceiveBuffer));
                var _options,i;
                _options = read_ubyte(other.chatReceiveBuffer);
                ds_list_clear(options);
                for(i=0;i<_options && i<9;i+=1) {
                    ds_list_add(options,read_string(other.chatReceiveBuffer,read_ubyte(other.chatReceiveBuffer)));
                }
                
                alarm[0] = 30*read_ubyte(other.chatReceiveBuffer);
            }
        } else if playerId == 201 {
            win = read_ubyte(chatReceiveBuffer);
            if win == 0 with(global.voter) instance_destroy();
            else {
                with(global.voter) {
                    win = other.win;
                    done = true;
                    alarm[0] = 90;
                }
            }
        } else if playerId == 202 {
            (ds_list_find_value(global.players,read_ubyte(chatReceiveBuffer))).hasMiku = true;
        // some option has more votes now
        } else if playerId == 203 {
            var option;
            option = read_ubyte(chatReceiveBuffer);
            with (global.voter) {
                optionVotes[option] += 1;
                total += 1;
            }
        } else if playerId == 204 {
            //this packet contains a vote + statistics for when you join an existing vote
            with(global.voter) instance_destroy();
            instance_create(0,0,global.voter);
            with(global.voter) {
                question = read_string(other.chatReceiveBuffer,read_ubyte(other.chatReceiveBuffer));
                var _options,i;
                _options = read_ubyte(other.chatReceiveBuffer);
                ds_list_clear(options);
                for(i=0;i<_options && i<9;i+=1) {
                    ds_list_add(options,read_string(other.chatReceiveBuffer,read_ubyte(other.chatReceiveBuffer)));
                }
                
                alarm[0] = 30*read_ubyte(other.chatReceiveBuffer);
            
                for(i=0;i<_options;i+=1) {
                    optionVotes[i] = read_ubyte(other.chatReceiveBuffer);
                    total += optionVotes[i];
                }
            }
        } else {
            _team = 0;
            _message = read_string(chatReceiveBuffer,read_ubyte(chatReceiveBuffer));
            event_user(4); //add to chatwindow
        }
        
        buffer_clear(chatReceiveBuffer);
        PluginPacketPop(global.chatPacketID);
    }
');

//event7 : check if the player isn't spamming
//this event can also be used by other plugins to read each message!
object_event_add(global.chatWindow,ev_other,ev_user7,'
    if _player.lastChatTime > current_time-2000 {
        _player.chatCount += 1;
        //5 is a little too lenient 
        if _player.chatCount > 4 {
            //mute player.            
            _message = "O"+_player.name+" has been muted due to spamming.";
            _team = 0;
            playerId = 254;
            event_user(2); //tell everyone someone got muted
            event_user(4); //add to own chat
            
            _player.hasChat = false;
            ds_list_add(global.chatBanlist,socket_remote_ip(_player.socket));
        }
    } else _player.chatCount = 1;
    _player.lastChatTime = current_time;
');

//event8 : handle voting
object_event_add(global.chatWindow,ev_other,ev_user8,"
    if ds_list_size(voteCommand) > 0 {
        if votePlayer == _player {
            execute_string(ds_map_find_value(global.voteCommandMap,ds_list_find_value(voteCommand,0)),voteCommand,vote,_player);
            ds_list_clear(votes);
            vote = 0;
            //important! votePlayer commands have to clear the voteCommand and votePlayer themselves!
            alarm[0] = -1;
        } else if votePlayer == noone {
            ds_list_add(votes,vote);
            // tell plebs about the votes IN REAL TIME
            with(Player) {
                if hasChat and !(global.isHost and id == global.myself) and mayVote {
                    write_ubyte(global.chatSendBuffer,203);
                    write_ubyte(global.chatSendBuffer,other.vote - 1);
                    PluginPacketSendTo(global.chatPacketID,global.chatSendBuffer,id);
                    buffer_clear(global.chatSendBuffer);
                }
            }
            // if I'm not a pleb, tell me IN REALER TIME!!!!
            if (global.isHost)
                with (global.voter) {
                    optionVotes[other.vote - 1] += 1;
                    total += 1;
                }
            if ds_list_size(votes) >= ds_list_size(global.players) {
                alarm[0] = 1;
            }
        }
    }
");

//event9 : send the message to everyone or execute the command
object_event_add(global.chatWindow,ev_other,ev_user9,"
    if string_copy(_message,1,1) != '/' {
        playerId = ds_list_find_index(global.players,_player);
        target = Player;
        event_user(2); //send
        event_user(4); //add to chatwindow
    } else {
        event_user(12); //parse a string
        //execute the command
        var found;
        found = false;
        if _player == global.myself {
            if ds_map_exists(global.clientCommandMap,string_lower(ds_list_find_value(arguments,0)))  {
                execute_string(ds_map_find_value(global.clientCommandMap,string_lower(ds_list_find_value(arguments,0))),arguments);
                found = true;
            }
        }
        if !found {
            if ds_map_exists(global.commandMap,string_lower(ds_list_find_value(arguments,0))) {
                if string_copy(string_lower(ds_list_find_value(arguments,0)),1,4) == 'vote' && _player!= global.myself {
                    if current_time-4000*60 > _player.lastVoteCall {
                        execute_string(ds_map_find_value(global.commandMap,string_lower(ds_list_find_value(arguments,0))),arguments,_player);
                        _player.lastVoteCall = current_time;
                    } else {
                        _team = 0;
                        playerId = 255;
                        _message = 'OPlease wait '+string(ceil((4000*60-(current_time-_player.lastVoteCall))/1000))+' seconds before starting a vote.';
                        target = _player;
                        event_user(2);
                    }
                } else if ds_list_find_index(global.blockedCommands,string_lower(ds_list_find_value(arguments,0))) >= 0 && _player != global.myself && string_lower(ds_list_find_value(arguments,0)) != 'help' {
                    _team = 0;
                    playerId = 255;
                    _message = 'OSorry this command has been blocked by the host.'
                    target = _player;
                    event_user(2);
                } else execute_string(ds_map_find_value(global.commandMap,string_lower(ds_list_find_value(arguments,0))),arguments,_player);
            } else {
                _team = 0;
                playerId = 255;
                _message = 'OSorry this command does not exist. Type /help for console commands.'
                target = _player;
                if target == global.myself event_user(4);
                else event_user(2);
            }
        }
    }
");

//event10 : send a vote request and create it if needed
object_event_add(global.chatWindow,ev_other,ev_user10,"
    alarm[0] = 30*_time;
    if target != Player votePlayer = target;
    if target == global.myself || target == Player {
        global.myself.canVote = true;
        with(global.voter) instance_destroy();
        instance_create(0,0,global.voter);
        with(global.voter) {
            ds_list_clear(options);
            question = other._question;
            var i;
            for(i=0;i<ds_list_size(other.options) && i<9;i+=1) {
                ds_list_add(options,ds_list_find_value(other.options,i));
            } 
            alarm[0] = 30*other._time;
        }
    }
    if target != global.myself {
        write_ubyte(global.chatSendBuffer,200);
        write_ubyte(global.chatSendBuffer,min(255,string_length(_question)));
        write_string(global.chatSendBuffer,string_copy(_question,0,255));
        write_ubyte(global.chatSendBuffer,ds_list_size(options));
        var i;
        for(i=0;i<ds_list_size(options);i+=1) {
            write_ubyte(global.chatSendBuffer,min(255,string_length(ds_list_find_value(options,i))));
            write_string(global.chatSendBuffer,string_copy(ds_list_find_value(options,i),0,255));
        }
        write_ubyte(global.chatSendBuffer,_time);
        with(target) {
            //don't tell people who may not vote at the moment
            if hasChat = true && mayVote {
                canVote = true;
                PluginPacketSendTo(global.chatPacketID,global.chatSendBuffer, id);
            }
        }
        buffer_clear(global.chatSendBuffer);
    }
");

//event11 : send vote results
object_event_add(global.chatWindow,ev_other,ev_user11,"
    alarm[0] = -1;
    write_ubyte(global.chatSendBuffer,201);
    write_ubyte(global.chatSendBuffer,win);
    if votePlayer == noone {
        with(Player) {
            if hasChat = true && mayVote PluginPacketSendTo(global.chatPacketID,global.chatSendBuffer, id);
        }
        buffer_clear(global.chatSendBuffer);
    } else {
        with(votePlayer) {
            if hasChat = true PluginPacketSendTo(global.chatPacketID,global.chatSendBuffer, id);
        }
        buffer_clear(global.chatSendBuffer);
    }
    
    if votePlayer == global.myself || votePlayer == noone {
        if win == 0 {
            with(global.voter) instance_destroy();
        } else {
            with(global.voter) {
                win = other.win;
                done = true;
                alarm[0] = 90;
            }
        }
    }
");

//event12 : parsing a string into the arguments list (probably overcomplicated but eh, it works)
object_event_add(global.chatWindow,ev_other,ev_user12,"
    var pos, quotePos, _message2;
    ds_list_clear(arguments);
    _message2 = string_copy(_message,2,string_length(_message));

    var _command, _args;
    pos = string_pos(' ',_message2);
    if (pos) {
        _command = string_copy(_message2, 1, pos - 1);
        _args = string_copy(_message2, pos + 1, string_length(_message2) - pos);
    } else {
        _command = _message2;
        _args = '';
    }
    // only parse arguments if it's not /me, /nick, /votemute, /mute
    // they're special
    // ok?
    if (string_lower(_command) != 'me' and string_lower(_command) != 'nick' and string_lower(_command) != 'votemute' and string_lower(_command) != 'mute') {
        ds_list_add(arguments, _command);
        _message2 = _args;
        while(_message2 != '') {
            pos = string_pos(' ',_message2);
            if string_char_at(_message2,1) == chr(34) {  //argument starts with a quote
                _message2 = string_copy(_message2,2,255); //remove the starting quote
                pos = string_pos(chr(34),string_copy(_message2,1,string_length(_message2)));
                while(string_char_at(_message2,pos+1) != ' ' && pos != 0) { //look for the 'ending' quote
                    quotePos = string_pos(chr(34),string_copy(_message2,pos+1,string_length(_message2)));
                    if quotePos == 0 pos = 0;
                    else pos += quotePos;
                }
                if pos != 0 _message2 = string_copy(_message2,1,pos-1)+string_copy(_message2,pos+1,255);
                else if string_char_at(_message2,string_length(_message2)) == chr(34) _message2 = string_copy(_message2,1,string_length(_message2)-1);
            }
            if pos == 0 {
                ds_list_add(arguments,_message2);
                _message2 = '';
            } else {
                ds_list_add(arguments,string_copy(_message2,1,pos-1));
                _message2 = string_copy(_message2,pos+1,255);
            }
        }
    } else {
        ds_list_add(arguments, _command);
        if (string_length(_args))
            ds_list_add(arguments, _args);
    }
");

object_event_add(global.chatWindow,ev_destroy,0,"
    ds_list_destroy(votes);
    ds_list_destroy(arguments);
    ds_list_destroy(options);
    ds_list_destroy(voteCommand);
    
    if global.map_rotation == fakeMaprotation {
        global.map_rotation = oldRotation;
        global.currentMapIndex = oldMapIndex;
    }
    ds_list_destroy(fakeMaprotation)

    ds_list_destroy(chatKicklist);
");

//chat logging
var currentDate;
currentDate = date_current_datetime();
global.timestamp = string(date_get_year(currentDate)) + "-";
if (date_get_month(currentDate) < 10) { global.timestamp = global.timestamp + "0"; }
global.timestamp += string(date_get_month(currentDate)) + "-";
if (date_get_day(currentDate) < 10) { global.timestamp = global.timestamp + "0"; }
global.timestamp += string(date_get_day(currentDate)) + " ";


object_event_add(global.chatWindow, ev_other, ev_game_end, '
    if (global.logChat == 1)
    {
        var chatLog, i;
        chatLog = file_text_open_append(working_directory + "\ServerPluginsData\Logs\" + global.timestamp + global.joinedServerName + ".log");
        for (i = 0; i < ds_list_size(global.chatLog); i += 1) {
            file_text_writeln(chatLog);
            file_text_write_string(chatLog, ds_list_find_value(global.chatLog, i));
        }
    }
    sleep(100);
');
//just to be sure muted people who rejoin the server are remuted
object_event_add(Player,ev_step,ev_step_normal,'
    if (ds_list_find_index(global.chatBanlist,socket_remote_ip(socket)) != -1)
    {
        hasChat = false;
    }
');


//import the other objects
execute_file(argument0+"/vote_api.gml");
execute_file(argument0+"/fake_menu.gml");
