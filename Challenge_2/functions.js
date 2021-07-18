var array = msg.payload;

var filt_line = [];

for(var line of array){
    for(const [col, content] of Object.entries(line)){
        
        if(content != undefined && content.includes("Publish Message") ){
            //there just need to be a publish message to select the entire row
            filt_line.push(line);
            break;
        }
    }
}


if(filt_line.length > 0){
    msg.payload = filt_line;
    return msg;
}

 //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 
var array = msg.payload;

var filt_line = [];

for(var line of array){
    
    var pub_msg_list = [];
    var payload_list = [];
    var map = [];

    for(const [col, content] of Object.entries(line)){
        if(content != undefined && content.includes("7b")){
            var msg_start_index = content.indexOf("7b");
            var msg_end_index = content.indexOf("7d")+2;
            payload_list.push(content.substring(msg_start_index, msg_end_index));
        }
    }
    
    for(const [col, content] of Object.entries(line)){
        if(content != undefined && content.includes("Publish Message")){
            var type_start_index = content.indexOf("Publish Message");
            var type_end_index = content.indexOf("]")+1;
            pub_msg_list.push(content.substring(type_start_index, type_end_index));
        }
    }
    
    if(pub_msg_list.length > 0 && payload_list.length > 0){
        pub_msg_list = pub_msg_list.slice(0, payload_list.length);
        
        for(i=0; i<payload_list.length; i++){
            map.push([pub_msg_list[i], payload_list[i]]);
        }
        
        filt_line.push(map);
    }
    
}


if(filt_line.length > 0){
    msg.payload = filt_line;
    return msg;
}

//++++++++++++++++++++++++++++++++++++++

var array = msg.payload;

var filt_line = [];

for(var line of array){
    for(var association of line){
        if(association[0].includes("factory/department1/section1/hydraulic_valve") || association[0].includes("factory/department3/section3/hydraulic_valve")){
            filt_line.push(association[1]);
        }
    }
}

if(filt_line.length > 0){
    msg.payload = filt_line;
    return msg;
}

//++++++++++++++++++++++++++++++++++++++

var array = msg.payload;

var filt_line = [];

for(var content of array){
    var hex = content.toString();
    var str = '';

    for (var i = 0; (i < hex.length && hex.substr(i, 2) !== '00'); i += 2){
        str += String.fromCharCode(parseInt(hex.substr(i, 2), 16));
    }
    
    var json = JSON.parse(str);
    filt_line.push(json.value);
}

if(filt_line.length > 0){
    msg.payload = filt_line;
    return msg;
}


//+++++++++++++++++++++++++++++++

var array = msg.payload;
var filt_line = [];

var API_KEY = "YOURAPIKEY";
var CHANNEL_ID = "1359547";

for(var value of array){
    var field1= json.value;
    msg.topic = 'channels/'+CHANNEL_ID+'/publish/' + API_KEY;
    msg.payload="field1="+field1+"&status=MQTTPUBLISH";
}

var API_KEY = "YOURAPIKEY";
var CHANNEL_ID = "1359547";
var field1= json.value;
msg.topic = 'channels/'+CHANNEL_ID+'/publish/' + API_KEY;
msg.payload="field1="+field1+"&status=MQTTPUBLISH";
return msg;

//+++++++++++++++++++++++++++++++

var value = msg.payload;

var API_KEY = "YOURAPIKEY";
var CHANNEL_ID = "1359547";
var field2= value;
msg.topic = 'channels/'+CHANNEL_ID+'/publish/' + API_KEY;
msg.payload="field2="+field2+"&status=MQTTPUBLISH";
return msg;

