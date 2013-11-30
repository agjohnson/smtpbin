: include header;

<script>
function redirect (form) {
    for (var i = 0; i < form.elements.length; i++) {
        var field = form.elements[i];
        if (field.name ==  'bin_id') {
            var url = "/bin/" + encodeURIComponent(field.value);
            window.location.href = url;
        }
    }
}
</script>

: if ($id) {
<h2>
  Bin Messages
    : if ($search) {
        : if ($user) {
      for user {% $user %}
        : }
    : }
</h2>
: }

: if ($messages) {

<ul id='bin' class='bin'>
</ul>

<script>
  var messages = new Messages();
  var message_view = new MessageView({model: messages});

    : for $messages -> $message {
  messages.add({
    id: "{% $message.id %}",
    subject: "{% $message.subject | truncate | mark_raw %}",
    datetime: "{% $message.natural_date %}",
    state: "{% $message.state %}"
  });

    : }
</script>

: } else {
<div class='email'>
    : if ($id) {
  <div class='header'>
    <span class='key'>X-Protip:</span>
    <span class='value'>Add the header X-Smtpbin-Id to collect mail in this bin.</span>
  </div>

  <div class='header'>
    <span class='key'>X-Smtpbin-Id:</span>
    <span class='value'>{% $id %}</span>
  </div>
    : } else {
  <h2>New Message Bin</h2>

  <p style='white-space: normal;'>
    Create a <a href='/bin/random'>random</a> message bin, or create a named
    message bin.
  </p>

  <form onsubmit='redirect(this); return false;'>
    <label for='bin_id'>Named message bin:</label>
    <input type='text' name='bin_id' id='bin_id' />
    <input type='submit' style='display: none;' />
  </form>
    : }
</div>
: }

: include footer;
