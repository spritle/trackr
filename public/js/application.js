function helloWorld() {}

function display_estimate(story_type){
    if(story_type == "feature")
        document.getElementById('story[estimate]').style.display = "block";
    else
        document.getElementById('story[estimate]').style.display = "none";
}

function display_div(div_id, li){
    if( $(li).hasClass("open")){
        $(li).removeClass("open");
        document.getElementById(div_id).style.display="none";
    }else{
        $(li).addClass("open");
        document.getElementById(div_id).style.display="block";
    }
}

function change_status(form, status){
    form.current_state.value = status
    form.submit();
}

function delete_story(form){
    if(confirm("Are you sure delete this story?")){
       form.submit();
    }
}