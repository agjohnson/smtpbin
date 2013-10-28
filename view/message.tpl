: include header;

<h2>Message</h2>

<div class='email'>
: for $message.headers -> $header {
  <div class='header' style='color: #998'>
    <span class='key'>{% $header.header %}:</span>
    <span class='value'>{% $header.value %}</span>
  </div>
: }

  <p>
    {% $part.body %}
  </p>
</div>

: include footer;
