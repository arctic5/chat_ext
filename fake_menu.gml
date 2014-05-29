//create a cheaty cheat object to prevent you from moving and opening chat menus while typing :p
global.cheatycheat = object_add();
object_set_parent(global.cheatycheat,InGameMenuController);
object_event_add(global.cheatycheat,ev_step,ev_step_normal,'//no');
object_event_add(global.cheatycheat,ev_draw,0,'//no');
object_event_add(global.cheatycheat,ev_keypress,vk_enter,'//no');
object_event_add(global.cheatycheat,ev_keypress,vk_escape,'
    with(global.chatWindow) open = false;
    instance_create(0,0,InGameMenuController);
    instance_destroy();
');