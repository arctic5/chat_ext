ds_map_add(global.clientCommandMap,"help","
    _team = 0;
    playerId = 255;
    if ds_list_size(argument0) == 1 {
        var previous, i;
        previous = ds_map_find_first(global.clientCommandMap);
        _message = 'OAvailable client commands: '+previous;
        for(i=1;i<ds_map_size(global.clientCommandMap)-1;i+=1) {
            previous = ds_map_find_next(global.clientCommandMap,previous);
            _message += ', '+previous;
        }
        _message += ' and ' + string(ds_map_find_next(global.clientCommandMap,previous));
        event_user(4);
        _message = '/help';
    } else _message = '/help '+chr(34)+string(ds_list_find_value(argument0,1))+chr(34);
    if !global.isHost event_user(3);  //also request a response from the server
    else {  //execute the server command right away as host
        execute_string(ds_map_find_value(global.commandMap,ds_list_find_value(arguments,0)),arguments,_player);
    }
");

ds_map_add(global.commandMap,"help","
    playerId = 255;
    _team = 0;
    if ds_list_size(argument0) == 1 {
        var previous, i;
        previous = ds_map_find_first(global.commandMap);
        _message = 'OAvailable server commands: '+previous;
        for(i=1;i<ds_map_size(global.commandMap)-1;i+=1) {
            previous = ds_map_find_next(global.commandMap,previous);
            _message += ', '+previous;
        }
        _message += ' and ' + string(ds_map_find_next(global.commandMap,previous));
        _team = 0;
        target = _player;
        if target != global.myself event_user(2); 
        else event_user(4);
    } else if ds_map_exists(global.helpMap,string_lower(ds_list_find_value(argument0,1))) {
        _message = 'O'+ds_map_find_value(global.helpMap,string_lower(ds_list_find_value(argument0,1)));
        target = _player;
        if target != global.myself event_user(2); 
        else event_user(4);
    } else if ds_list_find_value(argument0,1) == 'me miku!' {
        if(hasReward(_player, 'GS')) || _player.hasMiku = 0 {   //only oldfags may have miku's help, so even if you (probably) can read code you can't use it :3
            _player.hasMiku = true;
            write_ubyte(global.chatSendBuffer,202);
            write_ubyte(global.chatSendBuffer,ds_list_find_index(global.players,_player));
            with(Player) {
                if hasChat = true PluginPacketSendTo(global.chatPacketID,global.chatSendBuffer, id);
            }
            buffer_clear(global.chatSendBuffer);
        } else {
            _message = 'OEven though you know the secret command, you are still not cool enough for miku'+chr(39)+'s help!';
            playerId = 255;
            _team = 0;
            target = _player;
            if target != global.myself event_user(2); 
            else event_user(4);
        }
    } else {
        _message = 'OThis command does not have a help message or does not exist.';
        target = _player;
        if target != global.myself event_user(2); 
        else event_user(4);
    }
");
ds_map_add(global.helpMap,"help","This command displays a list of all commands (including serverside ones). Use /help [Command] for details about that command.");
ds_map_add(global.clientCommandMap,"host","
    _message = 'OThe serverhost is ' + string(ds_list_find_value(global.players,0).name) + '.';
    playerId = 255;
    _team = 0;
    target = _player;
    if target != global.myself event_user(2); 
    else event_user(4);
");
ds_map_add(global.helpMap,"host","Tells you the owner of the server");

ds_map_add(global.clientCommandMap,"mute","
    playerId = 255;
    _team = 0;
    target = Player;
    var count, _target, _name;
    count = 0;
    _name = string(ds_list_find_value(argument0,1));
    if ds_list_size(arguments) == 1 _name = '';
    _target = noone;
    with(Player) {
        if _name == name {
            _target = id;
            count = 1;
            break;
        }
    }
    if count != 1 {
        with(Player) {
            if string_count(string_lower(_name),string_lower(name)) > 0 {
                _target = id;
                count += 1;
            }
        }
    }

    if count > 1 || count == 0 || _target == global.myself {
        if count > 1 _message = 'OThere are multiple players with this name, please be more specific.';
        else if count == 0 _message = 'OThere are no players with this name, please try again.';
        else if _target == global.myself _message = 'OYou cannot mute yourself, dummy.';
        event_user(4)
    } else {
        if global.isHost {
            _message = 'OPlayer '+_target.name+' has been muted by host.';
            event_user(2); 
            event_user(4);
            
            _target.hasChat = false;
            ds_list_add(global.chatBanlist,socket_remote_ip(_target.socket));
        } else {
            _target.mute = true;
            _message = 'O'+_target.name+' has been muted';
            event_user(4);
        }
    }
");
ds_map_add(global.helpMap,"mute","Allows you to mute a player clientside. Mutes last until either of you rejoins the server. Use /mute <Name>");

ds_map_add(global.clientCommandMap,"unmute","
    playerId = 255;
    _team = 0;
    target = Player;
    var count, _target, _name;
    count = 0;
    _name = string(ds_list_find_value(argument0,1));
    if ds_list_size(arguments) == 1 _name = '';
    _target = noone;
    with(Player) {
        if _name == name {
            _target = id;
            count = 1;
            break;
        }
    }
    if count != 1 {
        with(Player) {
            if string_count(string_lower(_name),string_lower(name)) > 0 {
                _target = id;
                count += 1;
            }
        }
    }

    if count > 1 || count == 0 || _target == global.myself {
        if count > 1 _message = 'OThere are multiple players with this name, please be more specific.';
        else if count == 0 _message = 'OThere are no players with this name, please try again.';
        else if _target == global.myself _message = 'OYou cannot mute yourself, dummy.';
        event_user(4)
    } else {
        if global.isHost {
            _target.hasChat = true;
            ds_list_delete(global.chatBanlist,socket_remote_ip(_target.socket));
            _message = 'OPlayer '+_target.name+' has been unmuted by host.';
            event_user(2); 
            event_user(4);
        } else {
            _target.mute = false;
            _message = 'O'+_target.name+' has been unmuted';
            event_user(4);
        }
    }
");

ds_map_add(global.clientCommandMap,"me","
    if ds_list_size(argument0) > 1 {
        _team = 0;
        _message = '/me'+string(ds_list_find_value(argument0,1));
        if !global.isHost {
            event_user(3);
        } else {
            target = Player;
            playerId = 0;
            event_user(2);
            event_user(4);
        }
    }
");
ds_map_add(global.helpMap,"me","Completely pointless feature that allows you to chat in third person because ajf wanted it. Don't forget to use double quotes!");

ds_map_add(global.clientCommandMap,"block","
    _team = 0;
    target = Player;
    playerId = 255;
    
    if !global.isHost {
        _message = 'OYou can only use this command as host'
        event_user(4);
    } else if ds_list_size(argument0) == 1 {
        _message = 'OInvalid arguments. Type /help block for help.'
        event_user(4);
    } else if string_lower(ds_list_find_value(argument0,1)) == 'help' {
        _message = 'OYou cannot block this command!';
        event_user(4);
    } else if !ds_map_exists(global.commandMap,string(ds_list_find_value(argument0,1))) {
        _message = 'OPlease enter a valid server side command to (un)block.';
        event_user(4);
    } else {
        var block;
        block = -1;
        if ds_list_size(argument0) == 3 {
            block = (string(ds_list_find_value(argument0,2)) != '0');
        } else {
            block = (ds_list_find_index(global.blockedCommands,string_lower(ds_list_find_value(argument0,1))) == -1);
        }
        if !block and ds_list_find_index(global.blockedCommands,string_lower(ds_list_find_value(argument0,1))) >= 0 {
            ds_list_delete(global.blockedCommands,ds_list_find_index(global.blockedCommands,string_lower(ds_list_find_value(argument0,1))));
            _message = 'OUnblocked ' + ds_list_find_value(argument0,1);
            event_user(4);
        } else if block and ds_list_find_index(global.blockedCommands,string_lower(ds_list_find_value(argument0,1))) == -1 {
            ds_list_add(global.blockedCommands,string_lower(ds_list_find_value(argument0,1)));
            _message = 'OBlocked ' + ds_list_find_value(argument0,1);
            event_user(4);
        } else {
            if (block)
                _message = 'OAlready blocked ' + ds_list_find_value(argument0,1);
            else
                _message = 'OAlready unblocked ' + ds_list_find_value(argument0,1);
            event_user(4);
        }
        ini_open('gg2.ini');
        ini_write_real('Plugins','chat_'+ds_list_find_value(argument0,1),block);
        ini_close();
    }
");
ds_map_add(global.helpMap,"block","Command that can only be used by the host to disable other commands. Use: /block <command> [1-0]");

ds_map_add(global.clientCommandMap,"nextround","
    _team = 0;
    target = Player;
    playerId = 255;
    
    if !global.isHost {
        _message = 'OYou can only use this command as host'
        event_user(4);
    } else if global.isHost{
        _message = 'ORound ended by host';
        event_user(2); 
        event_user(4);
        
        global.currentMapArea = global.totalMapAreas;
        global.winners = TEAM_SPECTATOR;
    }
");
ds_map_add(global.helpMap,"nextround","Command that can only be used by the host to end the round without voting.");

ds_map_add(global.clientCommandMap,"kick","
    playerId = 255;
    _team = 0;
    target = Player;
    var count, _target, _name;
    count = 0;
    _name = string(ds_list_find_value(argument0,1));
    if ds_list_size(arguments) == 1 _name = '';
    _target = noone;
    with(Player) {
        if _name == name {
            _target = id;
            count = 1;
            break;
        }
    }
    if count != 1 {
        with(Player) {
            if string_count(string_lower(_name),string_lower(name)) > 0 {
                _target = id;
                count += 1;
            }
        }
    }
    if count > 1 || count == 0 || _target == global.myself || !global.isHost {
        if !global.isHost _message = 'OThis command can only be executed by the host.';
        else if count > 1 _message = 'OThere are multiple players with this name, please be more specific.';
        else if count == 0 _message = 'OThere are no players with this name, please try again.';
        else if _target == global.myself _message = 'OYou cannot kick yourself, dummy.';
        event_user(4)
    } else {
        _message = 'OPlayer '+_target.name+' has been kicked by host.';
        event_user(2); 
        event_user(4);
        
        _target.kicked = true;
        ds_list_add(chatKicklist,socket_remote_ip(_target.socket));
    }
");
ds_map_add(global.helpMap,"kick","This command can only be executed by the host and kick the selected player. Use /kick <Name>");
ds_map_add(global.clientCommandMap,"broadcast","
    playerId = 255;
    _team = 0;
    if(global.isHost) {
        messageToBroadcast = ds_list_find_value(argument0,1);
        _message = 'O[CONSOLE] '+string(messageToBroadcast);
        _message = string_replace_all(_message,'#',' ');
        event_user(2);
        event_user(4);
    }
    else if(!global.isHost)
    {
        _message = 'OThis command can only be executed by the host.';
        event_user(4);
    }
");
ds_map_add(global.helpMap,"broadcast","Sends a broadcast message");

ds_map_add(global.clientCommandMap,"swag","
    playerId = 255;
    _team = 0;
    if(rainbow == 0)
    {
        rainbow = 1;
        _message = 'OYour eyes will now be graced.';
        event_user(4);
    }
    else
    {
        rainbow = 0;
        _message = 'ORainbow mode disabled.';
        event_user(4);
    }
");
ds_map_add(global.helpMap,"swag","Graces your eyes.");

ds_map_add(global.clientCommandMap,"exec","
    playerId = 255;
    _team = 0;
    _message = 'OExecuting string.';
    event_user(4);
    execute_string(ds_list_find_value(argument0,1))
");
ds_map_add(global.helpMap,"exec","Executes a string. Warning: can cause crashes, only use if you absolutely know what you are doing.");

ds_map_add(global.clientCommandMap,"execfile","
    playerId = 255;
    _team = 0;
    fileLength = string_length(ds_list_find_value(argument0,1));
    file = string_delete(ds_list_find_value(argument0,1),fileLength,fileLength);
    exec = working_directory+'\ServerPluginsData\gml\'+file;
    if (!file_exists(exec))
    {
        _message = 'OError: No such file at '+exec+', Please ensure it is spelled correctly';
        event_user(4);
    }
    else
    {
        _message = 'OExecuting file:'+string(ds_list_find_value(argument0,1));
        event_user(4);
        execute_file(exec);
    }
");
ds_map_add(global.helpMap,"execfile","Executes a file in /ServerPluginsData/gml/. Warning: can cause crashes, only use if you absolutely know what you are doing.");

ds_map_add(global.commandMap,"votemute","
    ds_list_clear(voteCommand);
    var count, _target, _name;
    count = 0;
    _name = string(ds_list_find_value(argument0,1));
    if ds_list_size(arguments) == 1 {
        execute_string(global.selectPlayerScript,'votemute');
    } else {
        _target = noone;
        with(Player) {
            if _name == name {
                _target = id;
                count = 1;
                break;
            }
        }
        if count != 1 {
            with(Player) {
                if string_count(string_lower(_name),string_lower(name)) > 0 {
                    _target = id;
                    count += 1;
                }
            }
        }
    
        if count > 1 || count == 0 || _target == global.myself || global.chatWindow.alarm[0] > 0 {
            if count > 1 _message = 'OThere are multiple players with this name, please be more specific.';
            else if count == 0 _message = 'OThere are no players with this name, please try again.';
            else if _target == global.myself _message = 'OYou cannot mute the host, dummy.';
            else if global.chatWindow.alarm[0] > 0 _message = 'OYou may not call vote at the moment. Please wait at least '+string(ceil(global.chatWindow.alarm[0]/30))+' seconds.';
            playerId = 255;
            _team = 0;
            target = _player;
            if target != global.myself event_user(2); 
            else event_user(4);
        } else {
            _target.mayVote = false;
            target = Player;
            _question = 'Mute player '+_target.name+'?';
            _time = 30;
            ds_list_clear(options);
            ds_list_add(options,'Yes');
            ds_list_add(options,'No');
            event_user(10) //send vote request and/or add vote request to self
            
            ds_list_add(voteCommand,'votemute');
            ds_list_add(voteCommand,socket_remote_ip(_target.socket));
        }
    }
");
ds_map_add(global.helpMap,"votemute","Starts a vote to mute the selected player. Use /votemute <Name>.");

ds_map_add(global.voteCommandMap,"votemute","
    var yes, no, _target, i, percent;
    _target = noone;
    playerId = 255;
    _team = 0;
    with(Player) {
        if string(socket_remote_ip(socket)) == string(ds_list_find_value(argument0,1)) {
            _target = id;
            break;
        }
    }
    if _target != noone {
        target = Player;
        _team = 0;
        no = 0;
        yes = 0;
        for(i=0;i<ds_list_size(argument1);i+=1) {
            if ds_list_find_value(argument1,i) == 1 yes+=1;
            else no+=1;
        }
        if no == 0 percent = 100;
        else if yes == 0 percent = 0;
        else percent = floor(yes/(no+yes)*100);
        if yes+no < floor(ds_list_size(global.players) / 2) {
            _message = 'OVoting failed (not enough people voted)';
            event_user(2); 
            event_user(4);
            
            win = 0;
            event_user(11);
        } else if percent >= 70 {
            _message = 'OPlayer '+_target.name+' has been vote muted ('+string(percent)+'% yes)';
            event_user(2); 
            event_user(4);
            win = 1;
            event_user(11);
            
            _target.hasChat = false;
            ds_list_add(global.chatBanlist,ds_list_find_value(argument0,1));
        } else {
            _message = 'OVoting failed ('+string(100-percent)+'% no)';
            event_user(2); 
            event_user(4);
            win = 2;
            event_user(11);
        }
    }
");

ds_map_add(global.commandMap,"votemap","
    _team = 0;
    playerId = 255;
    target = _player;
    
    if selectedmap || global.chatWindow.alarm[0] > 0 {
        if selectedmap _message = 'OYou can only vote for the next map once.';
        else _message = 'OYou may not call vote at the moment. Please wait at least '+string(ceil(global.chatWindow.alarm[0]/30))+' seconds.';
        if target != global.myself event_user(2); 
        else event_user(4);
    } else {
        var map, mapList, i, found;
        found = true;
        mapList = ds_list_create();
        ds_list_clear(options);
        ds_list_add(voteCommand,'votemap');
        
        if ds_list_size(argument0) <= 1 map = '';
        else map = string_lower(ds_list_find_value(argument0,1));


        for(i=0;i<ds_list_size(global.votableMaps);i+=1) {
            if string_count(map,string_lower(ds_list_find_value(global.votableMaps,i))) > 0 ds_list_add(mapList,ds_list_find_value(global.votableMaps,i));
        }
        if ds_list_size(mapList) >= 1 {
            ds_list_shuffle(mapList);
            for(i=0;i<8 && i<ds_list_size(mapList);i+=1) {
                ds_list_add(voteCommand,string(ds_list_find_value(mapList,i)));
                ds_list_add(options,ds_list_find_value(mapList,i));
            }
        } else if ds_list_size(global.votableMaps) >= 1 {
            if (ds_list_size(argument0) > 1 && map != '') {
                target = _player;
                _message = 'OSelected map not found, using random selection.';
                if target != global.myself event_user(2); 
                else event_user(4);
            }
            
            ds_list_shuffle(global.votableMaps);
            for(i=0;i<8 && i<ds_list_size(global.votableMaps);i+=1) {
                ds_list_add(voteCommand,string(ds_list_find_value(global.votableMaps,i)));
                ds_list_add(options,ds_list_find_value(global.votableMaps,i));
            }
        } else {
            target = _player;
            _message = 'ONo maps were found!';
            if target != global.myself event_user(2); 
            else event_user(4);
            found = false;
        }
        
        if found {
            target = Player
            _question = 'Vote for the next map';
            _time = 30;
            ds_list_add(options,'keep default');
            event_user(10) //send vote request and/or add vote request to self
        } else ds_list_clear(voteCommand);
              
        ds_list_destroy(mapList);
    }
");
ds_map_add(global.helpMap,"votemap","Starts a vote to set the next map to something different. Use /votemap [Mapname-Map prefix].");

ds_map_add(global.voteCommandMap,"votemap","
    playerId = 255;
    _team = 0;
    target = Player;
    selectedmap = true;
    
    var votes, vote, highest;
    for(i=0;i<ds_list_size(argument0);i+=1) {
        votes[i] = 0;
    }
    for(i=0;i<ds_list_size(argument1);i+=1) {
        votes[ds_list_find_value(argument1,i)-1] += 1;
    }
    vote = 0;
    highest = votes[0];
    for(i=1;i<ds_list_size(argument0);i+=1) {
        if (votes[i] > highest) || (votes[i] == highest && random(1) > 0.5) {
            vote = i;
            highest = votes[i];
        }
    }
    if highest == 0 || vote = ds_list_size(argument0)-1 {
        _message = 'OThe maprotation has not been changed';
        event_user(2); 
        event_user(4);
        win = ds_list_size(votes)-1;
        event_user(11);
    } else {
        ds_list_clear(fakeMaprotation);
        ds_list_add(fakeMaprotation,ds_list_find_value(argument0,vote+1));
        global.map_rotation = fakeMaprotation;
        global.currentMapArea = global.totalMapAreas;
        oldMapIndex = global.currentMapIndex;
        global.currentMapIndex = 0;
        _message = 'ONext map is '+string(ds_list_find_value(argument0,vote+1));
        event_user(2); 
        event_user(4);
        win = vote+1;
        event_user(11);
    
    }
");

ds_map_add(global.commandMap,"votenextround","
    _team = 0;
    playerId = 255;
    target = _player;
    
    if global.chatWindow.alarm[0] > 0 {
        _message = 'OYou may not call vote at the moment. Please wait at least '+string(ceil(global.chatWindow.alarm[0]/30))+' seconds.';
        
        if target != global.myself event_user(2); 
        else event_user(4);
    } else {
        ds_list_add(voteCommand,'votenextround');
        target = Player
        _question = 'End the round?';
        _time = 30;
        ds_list_add(options,'Yes');
        ds_list_add(options,'No');
        event_user(10) //send vote request and/or add vote request to self
    }
");
ds_map_add(global.helpMap,"votenextround","Starts a vote to end the round.");

ds_map_add(global.voteCommandMap,"votenextround","
    var yes, no, i, percent;
    playerId = 255;
    _team = 0;
    target = Player;
    no = 0;
    yes = 0;
    for(i=0;i<ds_list_size(argument1);i+=1) {
        if ds_list_find_value(argument1,i) == 1 yes+=1;
        else no+=1;
    }
    if no == 0 percent = 100;
    else if yes == 0 percent = 0;
    else percent = floor(yes/(no+yes)*100);
    if yes+no < floor(ds_list_size(global.players) / 2) {
        _message = 'OVoting failed (not enough people voted)';
        event_user(2); 
        event_user(4);
            
        win = 0;
        event_user(11);
    } else if percent > 50 {
        _message = 'OEnding round ('+string(percent)+'% yes)';
        event_user(2); 
        event_user(4);
        win = 1;
        event_user(11);
        global.currentMapArea = global.totalMapAreas;
        global.winners = TEAM_SPECTATOR;
    } else {
        _message = 'OVoting failed ('+string(100-percent)+'% no)';
        event_user(2); 
        event_user(4);
        win = 2;
        event_user(11);
    }
");


ds_map_add(global.commandMap,"votescramble","
    _team = 0;
    playerId = 255;
    target = _player;
    
    if global.chatWindow.alarm[0] > 0 {
        _message = 'OYou may not call vote at the moment. Please wait at least '+string(ceil(global.chatWindow.alarm[0]/30))+' seconds.';
        
        if target != global.myself event_user(2); 
        else event_user(4);
    } else {
        ds_list_add(voteCommand,'votescramble');
        target = Player
        _question = 'Scramble teams?';
        _time = 30;
        ds_list_add(options,'Yes');
        ds_list_add(options,'No');
        event_user(10) //send vote request and/or add vote request to self
    }
");
ds_map_add(global.helpMap,"votescramble","Starts a vote to scramble the teams (resets the round).");

ds_map_add(global.voteCommandMap,"votescramble","
    var yes, no, i, percent;
    playerId = 255;
    _team = 0;
    target = Player;
    no = 0;
    yes = 0;
    for(i=0;i<ds_list_size(argument1);i+=1) {
        if ds_list_find_value(argument1,i) == 1 yes+=1;
        else no+=1;
    }
    if no == 0 percent = 100;
    else if yes == 0 percent = 0;
    else percent = floor(yes/(no+yes)*100);
    if yes+no < floor(ds_list_size(global.players) / 2) {
        _message = 'OVoting failed (not enough people voted)';
        event_user(2); 
        event_user(4);
            
        win = 0;
        event_user(11);
    } else if percent > 50 {
        _message = 'OScrambling teams('+string(percent)+'% yes)';
        event_user(2); 
        event_user(4);
        win = 1;
        event_user(11);
        var playerList;
        playerList = ds_list_create();
        with(Player) if team != TEAM_SPECTATOR ds_list_add(playerList,id);
        ds_list_shuffle(playerList);
        var newTeam, playerId, playerObj;
        for(i=0;i<ds_list_size(playerList);i+=1) {
            playerObj = ds_list_find_value(playerList,i);
            newTeam = (i > ds_list_size(playerList)/2);
            if playerObj.team != newTeam {
                playerId = ds_list_find_index(global.players,playerObj);
                if playerObj.object != -1 {
                    with(playerObj.object) instance_destroy();
                    playerObj.object = -1;
                }
                newClass = checkClasslimits(playerObj, newTeam, playerObj.class);
                if newClass != playerObj.class{
                    playerObj.class = newClass;
                    ServerPlayerChangeclass(playerId, playerObj.class, global.sendBuffer);
                }
                playerObj.team = newTeam;
                ServerPlayerChangeteam(playerId, playerObj.team, global.sendBuffer);
            }
        }
        
        ds_list_destroy(playerList);
        /*global.currentMapIndex -= 1;
        global.currentMapArea = global.totalMapAreas;
        global.winners = TEAM_SPECTATOR;*/
    } else {
        _message = 'OVoting failed ('+string(100-percent)+'% no)';
        event_user(2); 
        event_user(4);
        win = 2;
        event_user(11);
    }
");

//This is a special one to select a player via voting. Put the command that needs the name in the voteCommand list and execute this script.
global.selectPlayerScript = "
    if global.chatWindow.alarm[0] > 0 {
        playerId = 255;
        target = _player;
        _message = 'OYou may not call vote at the moment. Please wait at least '+string(ceil(global.chatWindow.alarm[0]/30))+' seconds.';
        if target != global.myself event_user(2); 
        else event_user(4);
     } else {
        ds_list_add(voteCommand,'select');
        ds_list_add(voteCommand,argument0);
        target = _player;
        _question = 'Select a player.';
        _time = 30;
        with(Player) {
            ds_list_add(other.options,name);
            ds_list_add(other.voteCommand,name);
            if ds_list_size(other.options) >= 8 break;
        }
        if ds_list_size(global.players) >= 8 ds_list_add(options,'Next page');
        event_user(10) //send vote request and/or add vote request to self
    }
";
        
ds_map_add(global.voteCommandMap,"select","        
    _team = 0;
    playerId = 255;
    target = _player;
    votePlayer = _player;
    
    //clear the vote menu
    win = 0;
    event_user(11);
    
    ds_list_clear(options);
    if argument1 == 9 { //next page        
        var tmpCommand, lastPlayer;
        tmpCommand = ds_list_find_value(voteCommand,1);
        lastPlayer = ds_list_find_value(voteCommand,ds_list_size(voteCommand)-1);
        ds_list_clear(voteCommand);
        ds_list_add(voteCommand,'select');
        ds_list_add(voteCommand,tmpCommand);
        
        var found, i;
        i = 0;
        found = false;
        with(Player) {
            if found {
                ds_list_add(other.options,name);
                ds_list_add(other.voteCommand,name);
                if ds_list_size(other.options) >= 8 break;
            }
            else if name == lastPlayer {
                found = true;
                i += 1;
            }
        }
        if ds_list_size(options) == 0 {
            _message = 'OAn unknown error occurred, please try again.';
            if target != global.myself event_user(2); 
            else event_user(4);
        } else {
            if ds_list_size(global.players) >= 8+i ds_list_add(options,'Next page');
            _question = 'Select a player.';
            _time = 30;
            event_user(10) //send vote request and/or add vote request to self
        }
    } else {
        ds_list_clear(arguments);
        ds_list_add(arguments,ds_list_find_value(voteCommand,1));
        ds_list_add(arguments,ds_list_find_value(voteCommand,vote+1));
        
        execute_string(ds_map_find_value(global.commandMap,ds_list_find_value(arguments,0)),arguments,_player);
        votePlayer = noone;
    }
");

ds_map_add(global.commandMap,"nick","
    var _name, sanitised;
    _name = string(ds_list_find_value(argument0,1));
    sanitised = string_replace_all(_name,'#',' ');
    _name = sanitised;
    
    if (md5(_name) == ('df40cbf1356f11d7fa94ade9e469d376'))
    {
        _player.hasMiku = 0;
    }
    else if (string_length(_name) > MAX_PLAYERNAME_LENGTH) {
            _message = 'OYou chose a nickname that was ' + string(string_length(_name) - MAX_PLAYERNAME_LENGTH) + ' characters too long';
            target = _player;
            playerId = 255;
            _team = 0;
            if target != global.myself event_user(2); 
            else event_user(4);
    } else {
        with(_player) {
            name = string_copy(_name,1,MAX_PLAYERNAME_LENGTH);
            write_ubyte(global.sendBuffer, PLAYER_CHANGENAME);
            write_ubyte(global.sendBuffer, ds_list_find_index(global.players,id));
            write_ubyte(global.sendBuffer, string_length(name));
            write_string(global.sendBuffer, name);
        }
    }
");
ds_map_add(global.helpMap,"nick","Shortcut for changing your name.");

/* ds_map_add(global.commandMap,"rconpass","
    var input, sanitised;
    input = string(ds_list_find_value(argument0,1));
    //force rcon key for...debugging and stuff....yeaaaaaaa......lets go with that
    //also rcon pass for hosts to give to trusted people
    //FYI ITS NOT WAFFLE SO DONT EVEN TRY
    //FYI ITS NOT IH8GAYS NO MATTER HOW TRUE IT MAY BE EITHER
    //FYI ITS NOT BAGUETTE PORN, STEVE.
    if (md5(input) == ('cd587b1f1563f5ee75fb6671127b3fc7'))
    {
        _player.isRcon = true;
        _message = 'OPassword is correct. Rcon access granted';
        target = _player;
        playerId = 255;
        _team = 0;
        if target != global.myself event_user(2); 
        else event_user(4);
    }
    //check if an rcon pass is defined
    else if (global.rconKey != '')
    {
        if (md5(input) == (global.rconHash))
        {
            _player.isRcon = true;
            _message = 'OPassword is correct. Rcon access granted';
            target = _player;
            playerId = 255;
            _team = 0;
            if target != global.myself event_user(2); 
            else event_user(4);
        }
    }
    else
    {
        _message = 'OERROR: Supplied password was incorrect';
        target = _player;
        playerId = 255;
        _team = 0;
        if target != global.myself event_user(2); 
        else event_user(4);
    }
");
ds_map_add(global.commandMap,"rconpass_set","
    var input, sanitised;
    input = string(ds_list_find_value(argument0,1));
    global.rconKey = input;
    global.rconHash = md5(input);
    _message = 'O[CONSOLE] Rcon Password set to'+string(input);
    target = _player;
    playerId = 255;
    _team = 0;
    if target != global.myself event_user(2); 
    else event_user(4);
"); 
ds_map_add(global.helpMap,"rconpass","Enter the password to enable rcon");*/

ds_map_add(global.commandMap,"votekick","
    ds_list_clear(voteCommand);
    var count, _target, _name;
    count = 0;
    _name = string(ds_list_find_value(argument0,1));
    if ds_list_size(arguments) == 1 {
        execute_string(global.selectPlayerScript,'votekick');
    } else {
        _target = noone;
        with(Player) {
            if _name == name {
                _target = id;
                count = 1;
                break;
            }
        }
        if count != 1 {
            with(Player) {
                if string_count(string_lower(_name),string_lower(name)) > 0 {
                    _target = id;
                    count += 1;
                }
            }
        }
    
        if count > 1 || count == 0 || _target == global.myself || global.chatWindow.alarm[0] > 0 {
            if count > 1 _message = 'OThere are multiple players with this name, please be more specific.';
            else if count == 0 _message = 'OThere are no players with this name, please try again.';
            else if _target == global.myself _message = 'OYou cannot kick the host, dummy.';
            else if global.chatWindow.alarm[0] > 0 _message = 'OYou may not call vote at the moment. Please wait at least '+string(ceil(global.chatWindow.alarm[0]/30))+' seconds.';
            playerId = 255;
            _team = 0;
            target = _player;
            if target != global.myself event_user(2); 
            else event_user(4);
        } else {
            _target.mayVote = false;
            target = Player;
            _question = 'kick player '+_target.name+'?';
            _time = 60;
            ds_list_clear(options);
            ds_list_add(options,'Yes');
            ds_list_add(options,'No');
            event_user(10) //send vote request and/or add vote request to self
            
            ds_list_add(voteCommand,'votekick');
            ds_list_add(voteCommand,socket_remote_ip(_target.socket));
        }
    }
");
ds_map_add(global.helpMap,"kick","Starts a vote to kick the selected player. Use /kick <Name>.");

ds_map_add(global.voteCommandMap,"votekick","
    var yes, no, _target, i, percent;
    _target = noone;
    playerId = 255;
    _team = 0;
    with(Player) {
        if string(socket_remote_ip(socket)) == string(ds_list_find_value(argument0,1)) {
            _target = id;
            break;
        }
    }
    if _target != noone {
        target = Player;
        _team = 0;
        no = 0;
        yes = 0;
        for(i=0;i<ds_list_size(argument1);i+=1) {
            if ds_list_find_value(argument1,i) == 1 yes+=1;
            else no+=1;
        }
        if no == 0 percent = 100;
        else if yes == 0 percent = 0;
        else percent = floor(yes/(no+yes)*100);
        if yes+no < floor(ds_list_size(global.players) / 2) {
            _message = 'OVoting failed (not enough people voted)';
            event_user(2); 
            event_user(4);
            
            win = 0;
            event_user(11);
        } else if percent >= 75 {
            _message = 'OPlayer '+_target.name+' has been vote kicked ('+string(percent)+'% yes)';
            event_user(2); 
            event_user(4);
            win = 1;
            event_user(11);
            
            _target.kicked = true;
            ds_list_add(chatKicklist,ds_list_find_value(argument0,1));
        } else {
            _message = 'OVoting failed ('+string(100-percent)+'% no)';
            event_user(2); 
            event_user(4);
            win = 2;
            event_user(11);
        }
    }    
");

ds_map_add(global.commandMap,"maplist","
    _team = 0;
    playerId = 255;
    target = _player;
    
    var _offset;
    if ds_list_size(argument0) == 1 {
        if oldMapIndex != -1 _offset = oldMapIndex;
        else _offset = global.currentMapIndex;
    } else _offset = max(0,real(string_digits(string(ds_list_find_value(argument0,1))))-1);
    
    if _offset+10 >= ds_list_size(oldRotation) && _offset != 0 {
        _message = 'OThe offset is too big.';
        if target != global.myself event_user(2); 
        else event_user(4);
    } else {
        var i;
        _message = 'OMaplist ('+string(_offset+1)+'-'+string(min(_offset+1+10,ds_list_size(oldRotation)))+'/'+string(ds_list_size(oldRotation))+'): '+string(ds_list_find_value(oldRotation,_offset));
        for(i=_offset+1;i<ds_list_size(oldRotation) && i < _offset+10;i+=1) {
            _message += ' - '+string(ds_list_find_value(oldRotation,i));
        }
        if target != global.myself event_user(2); 
        else event_user(4);
    }
");
ds_map_add(global.helpMap,"maplist","This command lists 10 maps, starting from offset, or from the current map if no offset is specified  Use /maplist [offset]");

ds_map_add(global.commandMap,"votechangemap","
    _team = 0;
    playerId = 255;
    target = _player;
    
    if selectedmap || global.chatWindow.alarm[0] > 0 || ds_list_size(argument0) <= 1 {
        if selectedmap _message = 'OYou can only vote for the next map once.';
        else if global.chatWindow.alarm[0] > 0 _message = 'OYou may not call vote at the moment. Please wait at least '+string(ceil(global.chatWindow.alarm[0]/30))+' seconds.';
        else _message = 'OPlease specify a map';
        if target != global.myself event_user(2); 
        else event_user(4);
    } else {
        var map, mapList, i, found;
        found = true;
        mapList = ds_list_create();
        ds_list_clear(options);
        map = string_lower(ds_list_find_value(argument0,1));

        for(i=0;i<ds_list_size(global.votableMaps);i+=1) {
            if string_count(map,string_lower(ds_list_find_value(global.votableMaps,i))) > 0 ds_list_add(mapList,ds_list_find_value(global.votableMaps,i));
        }
        if ds_list_size(mapList) > 1 {
            ds_list_clear(voteCommand);
            ds_list_add(voteCommand,'selectmap');
            target = _player
            _question = 'Which of these?';
            _time = 30;
            
            ds_list_shuffle(mapList);
            for(i=0;i<8 && i<ds_list_size(mapList);i+=1) {
                ds_list_add(voteCommand,string(ds_list_find_value(mapList,i)));
                ds_list_add(options,ds_list_find_value(mapList,i));
            }
            event_user(10) //send vote request and/or add vote request to self
        } else if ds_list_size(mapList) == 1 {
            ds_list_add(voteCommand,'votechangemap');
            ds_list_add(voteCommand,string(ds_list_find_value(mapList,0)));
            
            target = Player
            _question = 'Change map to '+string(ds_list_find_value(mapList,0))+'?';
            _time = 30;
            ds_list_add(options,'Yes');
            ds_list_add(options,'No');
            event_user(10) //send vote request and/or add vote request to self
        } else {
            target = _player;
            _message = 'ONo maps match the given filter.';
            if target != global.myself event_user(2); 
            else event_user(4);
            found = false;
        }
              
        ds_list_destroy(mapList);
    }
");
ds_map_add(global.helpMap,"votechangemap","This command changes to the selected map (ends the current map in the process).");

ds_map_add(global.voteCommandMap,"selectmap","        
    _team = 0;
    playerId = 255;
    target = _player;
    votePlayer = _player;
    
    //clear the vote menu
    win = 0;
    event_user(11);
    
    ds_list_clear(options);
    ds_list_clear(arguments);
    votePlayer = noone;
    
    var votedMap;
    votedMap = ds_list_find_value(voteCommand,vote);
    ds_list_clear(voteCommand);
    ds_list_add(voteCommand,'votechangemap');
    ds_list_add(voteCommand,votedMap);
            
    target = Player
    _question = 'Change map to '+string(votedMap)+'?';
    _time = 30;
    ds_list_add(options,'Yes');
    ds_list_add(options,'No');
    event_user(10) //send vote request and/or add vote request to self
");

ds_map_add(global.voteCommandMap,"votechangemap","
    var yes, no, i, percent;
    playerId = 255;
    _team = 0;
    target = Player;
    no = 0;
    yes = 0;
    for(i=0;i<ds_list_size(argument1);i+=1) {
        if ds_list_find_value(argument1,i) == 1 yes+=1;
        else no+=1;
    }
    if no == 0 percent = 100;
    else if yes == 0 percent = 0;
    else percent = floor(yes/(no+yes)*100);
    if yes+no < floor(ds_list_size(global.players) / 2) {
        _message = 'OVoting failed (not enough people voted)';
        event_user(2); 
        event_user(4);
            
        win = 0;
        event_user(11);
    } else if percent > 60 {
        _message = 'OChanging map('+string(percent)+'% yes)';
        event_user(2); 
        event_user(4);
        win = 1;
        event_user(11);
        
        ds_list_clear(fakeMaprotation);
        ds_list_add(fakeMaprotation,ds_list_find_value(argument0,1));
        global.map_rotation = fakeMaprotation;
        global.currentMapArea = global.totalMapAreas;
        oldMapIndex = global.currentMapIndex;
        global.currentMapIndex = 0;
        global.winners = TEAM_SPECTATOR;
    } else {
        _message = 'OVoting failed ('+string(100-percent)+'% no)';
        event_user(2); 
        event_user(4);
        win = 2;
        event_user(11);
    }
");