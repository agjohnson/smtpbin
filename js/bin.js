// SMTPbin - messages list

var backbone = require('backbone'),
    underscore = require('underscore'),
    jquery = require('jquery-browserify');

(function() {
  var $ = backbone.$ = jquery;
  var _ = backbone._ = underscore;

  // Backbone options
  backbone.emulateHTTP = true;

  // Message Object
  var Message = backbone.Model.extend({
    urlRoot: '/message',
    urlView: function (view) {
      if (view == 'html') {
        return this.url() + '.html';
      } else if (view == 'txt') {
        return this.url() + '.txt';
      } else {
        return this.url();
      }
    },
    sync : function (method, model, options) {
      options = options || {};
      if (method == 'delete') {
        options.url = model.url() + '/delete';
      }

      backbone.sync(method, model, options);
    }
  });

  // Collection
  var Messages = backbone.Collection.extend({
    model: Message
  });

  // Views
  var MessageListView = backbone.View.extend({
    el: '#bin',
    initialize: function () {
      this.listenTo(this.model, 'add', this.addOne);
    },
    addOne: function (model) {
      var message_view = new MessageView({model: model});
      $(this.$el).append(message_view.render().el);
    }
  });

  var MessageView = backbone.View.extend({
    tagName: 'li',
    initialize: function () {
      this.listenTo(this.model, 'change', this.render);
      this.listenTo(this.model, 'add', this.render);
      this.listenTo(this.model, 'destroy', this.remove);
    },
    render: function () {
      $(this.$el)
        .attr('id', 'message-' + this.model.get('id'))
        .addClass('state-' + this.model.get('state'));

      var el_subject = $('<div>')
        .addClass('subject')
        .html(this.model.get('subject'));

      // Links
      var el_time = $('<span>')
        .addClass('time')
        .html(this.model.get('datetime'));

      var el_view_text = $('<a>')
        .addClass('view')
        .attr('href', this.model.urlView())
        .html('view');

      var el_view_html = $('<a>')
        .addClass('view')
        .attr('href', this.model.urlView('html'))
        .html('html');

      var el_view_raw = $('<a>')
        .addClass('view')
        .attr('href', this.model.urlView('txt'))
        .html('raw');

      var el_delete = $('<span>')
        .append(
          $('<a>')
            .addClass('delete')
            .attr('href', '#')
            .html('delete')
        )

      var el_links = $('<div>')
        .addClass('links')
        .append(el_time)
        .append(" - ")
        .append(el_view_text)
        .append(", ")
        .append(el_view_html)
        .append(", ")
        .append(el_view_raw)
        .append(" - ")
        .append(el_delete);

      this.$el.append(el_subject);
      this.$el.append(el_links);
      return this;
    },
    events: {
      'click .delete': 'clear',
      'click .view': 'view'
    },
    view: function () {
      this.$el.addClass('state-read');
    },
    clear: function () {
      this.model.destroy();
    }
  });

  window.Message = Message;
  window.Messages = Messages;
  window.MessageView = MessageListView;
})();
