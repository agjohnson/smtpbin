// SMTPbin - messages list

var backbone = require('backbone'),
    underscore = require('underscore'),
    jquery = require('jquery-browserify');

(function() {
  var $ = backbone.$ = jquery;
  var _ = backbone._ = underscore;

  // Message Object
  var Message = backbone.Model.extend({
    urlRoot: '/message',
    urlView: function (view) {
      if (view == 'html') {
        return '/view' + this.url() + '.html';
      } else if (view == 'txt') {
        return '/view' + this.url() + '.txt';
      } else {
        return '/view' + this.url();
      }
    }
  });

  // Bin Object
  var Bin = backbone.Model.extend({
    urlRoot: '/bin',
  });

  // Collection
  var Messages = backbone.Collection.extend({
    model: Message
  });

  // Views
  var BinView = backbone.View.extend({
    el: '#bin',
    initialize: function () {
      this.messages = new Messages({model: Message});
      this.listenTo(this.messages, 'add', this.addOne);

      this.listenTo(this.model, 'change', this.render);
      this.model.fetch();
    },
    addOne: function (model) {
      var message_view = new MessageView({model: model});
      $(this.$el).append(message_view.render().el);
    },
    render: function (model) {
      var messages = this.model.get('messages');
      var bin = this;
      _.each(messages, function (message) {
        msg = new Message(message);
        bin.messages.add(msg);
      });
    }
  });

  // Single message view
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
        .addClass('state-' + this.model.get('state'))
        .empty();

      var subject = this.model.get('subject').replace(
        /^(.{70}[^\s]*).*/, "$1"
      ) + "\u2026";
      var el_subject = $('<div>')
        .addClass('subject')
        .html(subject);

      // Links
      var el_time = $('<span>')
        .addClass('time')
        .html(this.model.get('date'));

      var el_view_text = $('<a>')
        .addClass('view')
        .attr('href', '#')
        .html('view');

      var el_view_html = $('<a>')
        .addClass('view-html')
        .attr('href', '#')
        .html('html');

      var el_view_raw = $('<a>')
        .addClass('view-txt')
        .attr('href', '#')
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
      'click .view': function (ev) { this.view(ev); },
      'click .view-html': function (ev) { this.view(ev, 'html'); },
      'click .view-txt': function (ev) { this.view(ev, 'txt'); },
    },
    view: function (ev, format) {
      ev.preventDefault();
      this.$el.addClass('state-read');
      this.model.set('state', 'read');
      this.model.save();
      window.location = this.model.urlView(format);
    },
    clear: function () {
      this.model.destroy();
    }
  });

  window.Message = Message;
  window.Messages = Messages;
  window.Bin = Bin;
  window.BinView = BinView;
})();
