const Hooks = {};

Hooks.Scroll = {
  mounted() {
    this.handleEvent("new_message", () => {
      messages = document.getElementById('chat-messages')

      if(messages.scrollHeight > messages.clientHeight){
        messages.scrollTop = messages.scrollHeight
      }
      
    });
  },
};

export default Hooks;
