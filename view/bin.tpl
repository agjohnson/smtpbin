: include header;

<script>
function redirect (form) {
    for (var i = 0; i < form.elements.length; i++) {
        var field = form.elements[i];
        if (field.name ==  'bin_id') {
            var url = "/view/bin/" + encodeURIComponent(field.value);
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
    Create a <a href='/view/bin/random'>random</a> message bin, or create a named
    message bin.
  </p>

  <form onsubmit='redirect(this); return false;'>
    <label for='bin_id'>Named message bin:</label>
    <input type='text' name='bin_id' id='bin_id' />
    <input type='submit' style='display: none;' />
  </form>
    : }
</div>

<ul id='bin' class='bin'>
</ul>

<script>
  var bin = new Bin({id: '{% $id %}'});
  var bin_view = new BinView({
    model: bin
  });
</script>

: include footer;
