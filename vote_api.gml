//create an object that allows people to vote 'the tf2 way'
global.voter = object_add();
object_set_depth(global.voter, -110002);

object_event_add(global.voter,ev_create,0,"
    question = '';
    options = ds_list_create();
    optionVotes[0] = 0;
    var i;
    for (i = 1; i < 9; i += 1)
        optionVotes[i] = 0;
    total = 0;
    alarm[0] = 60*60;
    done = false;
    win = -1;
    alarm[1] = 5;	//creation cooldown
    start = false;
    vote = -1;
");

object_event_add(global.voter,ev_alarm,0,"instance_destroy();");
object_event_add(global.voter,ev_alarm,1,"start = true;");

object_event_add(global.voter,ev_step,ev_step_begin,"
    if !visible exit;
    if instance_exists(MenuController) || instance_exists(BubbleMenuZ) || instance_exists(BubbleMenuX) || instance_exists(BubbleMenuC) || instance_exists(TeamSelectController) || instance_exists(ClassSelectController) exit;
    if keyboard_check_pressed(ord('0')) {
        if global.isHost visible = false; //don't destroy the vote as host, we might need it when a player joins
        else instance_destroy();
    }
    
    if !done && start {
        vote = -1;
        if keyboard_check_pressed(ord('1')) {
            vote = 1;
        } else if keyboard_check_pressed(ord('2')) {
            vote = 2;
        } else if keyboard_check_pressed(ord('3')) {
            vote = 3;
        } else if keyboard_check_pressed(ord('4')) {
            vote = 4;
        } else if keyboard_check_pressed(ord('5')) {
            vote = 5;
        } else if keyboard_check_pressed(ord('6')) {
            vote = 6;
        } else if keyboard_check_pressed(ord('7')) {
            vote = 7;
        } else if keyboard_check_pressed(ord('8')) {
            vote = 8;
        } else if keyboard_check_pressed(ord('9')) {
            vote = 9;
        }
    
        if vote != -1 && vote <= ds_list_size(options) {
            done = true;
            if !global.isHost {
                write_ubyte(global.chatSendBuffer,3);
                write_ubyte(global.chatSendBuffer,vote);
                PluginPacketSend(global.chatPacketID,global.chatSendBuffer);
                buffer_clear(global.chatSendBuffer);
            } else if global.myself.canVote {
                with(global.chatWindow) {
                    vote = other.vote;
                    _player = global.myself;
                    global.myself.canVote = false;
                    event_user(8);
                }
            }
        }
    }
");

object_event_add(global.voter,ev_draw,0,"
    var xOffset, yOffset, width, height, i;
    
    width = string_width(question)-10;
    for(i=0;i<ds_list_size(options);i+=1) {
        width = max(width,string_width(ds_list_find_value(options,i)));
    }
    
    width = min(width,200);
    width += 15;
    height = 45+string_height(question)+ds_list_size(options)*20;
    xOffset = view_xview[0]+7;
    yOffset = max(view_yview[0]+333-height,view_yview[0]+7);
    
    draw_set_color(c_dkgray);
    draw_set_alpha(0.8);
    draw_rectangle(xOffset,yOffset,xOffset+width,yOffset+height,false);
    
    draw_set_color(c_black);
    draw_set_alpha(1);
    draw_rectangle(xOffset,yOffset,xOffset+width,yOffset+height,true);
    
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_font(global.consoleFont);
    draw_set_color(c_orange);
    draw_text(xOffset+8,yOffset+10,question);
    
    draw_set_color(c_white);
    for(i=0;i<ds_list_size(options);i+=1) {
        if done {
            if win == (i+1) draw_set_color(c_aqua);
            else if vote == (i+1) draw_set_color(c_orange);
            else draw_set_color(c_white); 
            
            if vote == (i+1) draw_text(xOffset+8,yOffset+20+string_height(question)+i*20,' > '+ds_list_find_value(options,i));
            else draw_text(xOffset+8,yOffset+20+string_height(question)+i*20,'   '+ds_list_find_value(options,i));
        } else {
            draw_set_color(c_white);
            draw_text(xOffset+8,yOffset+20+string_height(question)+i*20,string(i+1)+'. '+ds_list_find_value(options,i));
        }
        if (total and optionVotes[i]) {
            draw_set_color(c_aqua);
            draw_rectangle(xOffset+8,yOffset+20+string_height(question)+i*20+15,xOffset+8 + (width - 30) * (optionVotes[i] / total),yOffset+20+string_height(question)+i*20+17,false);
        }
    }
    draw_set_color(c_orange);
    draw_text(xOffset+8,yOffset+20+string_height(question)+i*20,'0. close | '+string(ceil(alarm[0]/30))+'s');
    draw_set_font(global.gg2Font);
");
