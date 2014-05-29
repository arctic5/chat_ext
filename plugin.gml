// Init
var createcode;
createcode = '
    if (!instance_exists(TeamChatWindow))
        instance_create(0, 0, TeamChatWindow);
';
//required plugin fallback code
if (global.serverPluginsRequired != 1) {global.serverPluginsRequired = 1;}

object_event_add(Spectator, ev_step, ev_step_end, createcode);

// Funcs
globalvar ds_list_from_back, string_section;

// returns the nth element from the back of a list
ds_list_from_back = '
    return ds_list_find_value(argument0, ds_list_size(argument0)-argument1-1);
';

// returns the mth n-length section of a string
string_section = '
    var str;
    str = string_delete(argument0, 1, argument2*argument1);
    return string_delete(str, argument1+1, string_length(str)-argument1);
';

// Vars
globalvar ChatPPS;
ChatPPS = argument1;

// Setup
globalvar TeamChatWindow, FakeMenu;
TeamChatWindow = object_add();
FakeMenu = object_add();

// Fake menu for catching input if we need it (while typing)
object_event_add(FakeMenu, ev_step, ev_step_normal, '');
object_event_add(FakeMenu, ev_draw, 0, '');
object_event_add(FakeMenu, ev_keypress, vk_enter, '');
object_event_add(FakeMenu, ev_keypress, vk_escape, '
    with(TeamChatWindow)
    {
        keyboard_string = "";
        typing = false;
    }
    with (FakeMenu)
        instance_destroy();
');
object_set_parent(FakeMenu, InGameMenuController);

object_set_depth(TeamChatWindow, -109999);

object_event_add(TeamChatWindow, ev_create, 0, '
    //preserve logs in between rounds
    globalvar lines, times;
    hosting = global.isHost;
    
    scrollback = 256;
    
    x = 24;
    y = -96;
    h = 40*6;
    w = 80*6;
    inputh = 20;
    lineh = 12;
    margins = 4;
    backcolor = $141810;
    entryback = $000000;
    
    lines = ds_list_create();
    times = ds_list_create();
    
    typing = false;
    
    ds_list_add(lines, "This server is running WarChat alpha 1, for GG2"+string(GAME_VERSION_STRING)+".");
    ds_list_add(times, current_time/30);
    
    ds_list_add(lines, "Press enter to toggle the typing mode, or esc to cancel it.");
    ds_list_add(times, current_time/30);
    
    ds_list_add(lines, "Ctrl+V can paste text, Ctrl+C copies the full editing text.");
    ds_list_add(times, current_time/30);
    
    b = buffer_create();
');

object_event_add(TeamChatWindow, ev_step, ev_step_normal, '
    if (keyboard_check_pressed(vk_enter) and !keyboard_check(vk_shift)
        and !(instance_exists(MenuController) and !instance_exists(FakeMenu)))
    {
        typing = !typing;
        if (typing)
            instance_create(0, 0, FakeMenu);
        else
        {
            with (FakeMenu)
                instance_destroy();
            
            if (keyboard_string == "")
                break;
            
            if (!global.isHost)
            {
                write_ubyte(b, 102); // 101 for team message
                write_ubyte(b, string_length(keyboard_string)); // len
                write_string(b, keyboard_string); // msg
                PluginPacketSend(ChatPPS, b);
                buffer_clear(b);
            }
            if (global.isHost) // Server has a variation on this because of lack of loopback
            {
                if (global.myself.team == TEAM_RED)
                    color = "R"
                else if (global.myself.team == TEAM_BLUE)
                    color = "B"
                var realstr;
                realstr = global.myself.name + ": " + keyboard_string;
                
                write_ubyte(b, 102); // 102 for team message
                write_ubyte(b, string_length(realstr)); // len
                write_string(b, realstr); // msg
                
                with (Player)
                {
                    PluginPacketSendTo(ChatPPS, other.b, id)
                }
                buffer_clear(b);
                
                ds_list_add(lines, realstr);
                ds_list_add(times, current_time/30);
            }
        }
        keyboard_string = "";
    }
    
    if (keyboard_check(vk_control) and keyboard_check_pressed(ord("V")) and clipboard_has_text())
    {
        keyboard_string += clipboard_get_text();
    }
    if (keyboard_check(vk_control) and keyboard_check_pressed(ord("C")))
    {
        clipboard_set_text(keyboard_string);
    }
    
    while (PluginPacketGetBuffer(ChatPPS) != -1)
    {
        d = PluginPacketGetBuffer(ChatPPS);
        
        cmd = read_ubyte(d);
        
        switch(cmd)
        {
        case 101: // Announce
            len = read_ubyte(d);
            msg = read_string(d, len);
            ds_list_add(lines, msg);
            ds_list_add(times, current_time/30);
            break;
        case 102: // Team message
            len = read_ubyte(d);
            msg = read_string(d, len);
            
            if (global.isHost)
            {
                msg = PluginPacketGetPlayer(ChatPPS).name + ": " + msg;
                var buf;
                buf = buffer_create();
                
                write_ubyte(buf, 102); // 102 for team message
                write_ubyte(buf, string_length(msg)); // len
                write_string(buf, msg); // msg
                
                with (Player)
                {
                    PluginPacketSendTo(ChatPPS, buf, id)
                }
                
                buffer_destroy(buf);
            }
            
            ds_list_add(lines, msg);
            ds_list_add(times, current_time/30);
            
            break;
        }
        
        PluginPacketPop(ChatPPS);
    }
');

object_event_add(TeamChatWindow, ev_draw, 0, '
    if (x >= 0)
        xs = x;
    else
        xs = view_wview + x - w;
        
    if (y >= 0)
        ys = y;
    else
        ys = view_hview + y - h;
    
    xs += view_xview;
    ys += view_yview;
    
    // Draw chatbox
    if (typing)
    {
        draw_set_alpha(0.5);
        draw_set_color(backcolor);
        draw_rectangle(xs, ys, xs + w - 1, ys + h - inputh - 1, false);
        draw_set_color(entryback);
        draw_rectangle(xs, ys + h - inputh, xs + w - 1, ys + h - 1, false);
    }
    
    // Draw chat lines as appropriate
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_alpha(1);
    draw_set_color(c_white);
    for (i = 0; i < ds_list_size(lines) and i < floor((h-inputh-margins*2)/lineh); i += 1)
    {
        if (!typing) // Fadeout for recent messages when not in chatbox mode
        {
            var t;
            t = current_time/30 - execute_string(ds_list_from_back, times, i);
            // A case for t <= 200 is not necessary because those should always come before t > 200 messages.
            if (t > 200 and t < 400)
                draw_set_alpha((400-t)/200);
            else if (t >= 400)
                break;
        }
        var str;
        str = execute_string(ds_list_from_back, lines, i)
        str = string_replace_all(str, "#", "\#");
        str = string_replace_all(str, chr(10), "");
        str = string_replace_all(str, chr(13), "");
        str = execute_string(string_section, str, 59, 0);
        draw_text(xs+margins, ys + h - inputh - margins - (i+1)*lineh, str);
    }
    if (typing)
    {
        var str;
        str = string_replace_all(keyboard_string, "#", "\#");
        str = string_replace_all(str, chr(10), "");
        str = string_replace_all(str, chr(13), "");
        str = execute_string(string_section, str, 59-string_length(global.myself.name)-2, 0);
        draw_text(xs+margins, ys + h - inputh + (inputh-lineh)/2, str);
    }
');
