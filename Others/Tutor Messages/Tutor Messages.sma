/*

    Tutor Съобщения, както от CZ. Управляват се от .ини файл, който се намира в configs.
    Известен бъг: След първото влизане и изтегляне на файловете, нещата не се изобразяват както трябва.
    Трябва рестартиране на играта, за да се изкарват нещата нормално.

*/

#include < amxmodx >

#define MAX_MESSAGES 50
#define MAX_MESSAGES_LEN 191

new file_name[ ] = { "tutor_messages.ini" }

enum
{    
    RED = 1,
    BLUE,
    YELLOW,
    GREEN
} 

new const tutor_files[ ][ ] = 
{
    "gfx/career/icon_!.tga",
    "gfx/career/icon_!-bigger.tga",
    "gfx/career/icon_i.tga",
    "gfx/career/icon_i-bigger.tga",
    "gfx/career/icon_skulls.tga",
    "gfx/career/round_corner_ne.tga",
    "gfx/career/round_corner_nw.tga",
    "gfx/career/round_corner_se.tga",
    "gfx/career/round_corner_sw.tga",
    "resource/TutorScheme.res",
    "resource/UI/TutorTextWindow.res"
}

new g_messages[ MAX_MESSAGES ][ MAX_MESSAGES_LEN+1 ]
new g_messagescount

new g_MsgTutor, g_MsgTutorClose
new g_maxplayers

new g_cvar[ 4 ]
new g_isconnected[ 33 ], g_isbot[ 33 ]

public plugin_precache()
{
    for( new i = 0; i < sizeof tutor_files; i++ ) 
        precache_generic( tutor_files[ i ] )
}

public plugin_init() 
{
    register_plugin( "Tutor Messages Shower", "2.0", "P.Of.Pw" )
    
    g_MsgTutor = get_user_msgid( "TutorText" )
    g_MsgTutorClose = get_user_msgid( "TutorClose" )
    
    g_cvar[ 0 ] = register_cvar( "amx_tutor_on", "1" )
    g_cvar[ 1 ] = register_cvar( "amx_tutor_msg_delay", "50.0" )
    g_cvar[ 2 ] = register_cvar( "amx_tutor_msg_color", "0" ) // 0-random ; 1-red; 2-blue; 3-yellow; 4-green
    g_cvar[ 3 ] = register_cvar( "amx_tutor_msg_hold_time", "7" )
    
    g_maxplayers = get_maxplayers()
    read_tutorfile()
    
    new Float:cvar_delay = get_pcvar_float( g_cvar[ 1 ] )
    set_task( cvar_delay, "show_messages", _, _, _, "b" )
}

public client_putinserver( id )
{
    g_isconnected[ id ] = true
    if( is_user_bot( id ) )
        g_isbot[ id ] = true
}

public client_disconnect( id )
{
    g_isconnected[ id ] = false
    g_isbot[ id ] = false
}

public show_messages()
{
    new cvar_on
    cvar_on = get_pcvar_num( g_cvar[ 0 ] )
    if( !cvar_on ) 
        return;
        
    new buffer[ 248 ], id, cvar_msg_color, cvar_msg_hold_time 

    cvar_msg_color = get_pcvar_num( g_cvar[ 2 ] )
    cvar_msg_hold_time = get_pcvar_num( g_cvar[ 3 ] )
        
    formatex( buffer, sizeof buffer - 1, "%s", g_messages[ random( g_messagescount ) ] )

    switch( cvar_msg_color )
    {
        case 0: cvar_msg_color = random_num( 0, 3 )
        case 1: cvar_msg_color = RED
        case 2: cvar_msg_color = BLUE
        case 3: cvar_msg_color = YELLOW
        case 4: cvar_msg_color = GREEN
    }
    
    for( id = 1; id <= g_maxplayers; id++ )
    {
        if( !g_isconnected[ id ] || g_isbot[ id ] )
            continue;
        
        make_tutor( id, buffer, cvar_msg_color, cvar_msg_hold_time )
    }
}

read_tutorfile()
{
    new dir[ 64 ]
    get_localinfo( "amxx_configsdir", dir, charsmax( dir ) )
    
    new file_path[ 64 ]
    formatex( file_path, charsmax( file_path ), "%s/%s", dir, file_name )
    
    if( !file_exists( file_path ) )
    {
        set_fail_state( "Customization file needed. Plugin stopped!" )
        pause( "a" )
    }
    
    new data[ MAX_MESSAGES_LEN ]
    new file = fopen( file_path, "rt" )
    
    while( !feof( file ) && g_messagescount < MAX_MESSAGES )
    {
        fgets( file, data, charsmax( data ) )
        trim( data )
        
        if( !strlen( data ) )
            continue;
        
        if( !data[ 0 ] )
            continue;
        
        switch( data[ 0 ] )
        {
            case '/': if( data[ 1 ] == '/' ) continue;
            case ';': continue;
            case ' ': continue;
        }

        copy( g_messages[ g_messagescount ], charsmax( g_messages[ ] ), data )
        g_messagescount++
    }
    
    fclose( file )
}

/*** Original by Leon McVeran ***/
stock make_tutor( id, text[ ], color, hold ) 
{
    message_begin( MSG_ONE_UNRELIABLE, g_MsgTutor, _, id )
    write_string( text )
    write_byte( 0 )
    write_short( 0 )
    write_short( 0 )
    write_short( 1 << color )
    message_end()

    if( hold > 1 ) 
    {
        set_task( float( hold ), "remove_tutor", id+1111 )
    }
}

public remove_tutor( taskID ) 
{
    new id = taskID - 1111

    message_begin( MSG_ONE_UNRELIABLE, g_MsgTutorClose, _, id )
    message_end()
}  
