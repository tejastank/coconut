var DesignView,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

DesignView = (function(_super) {

  __extends(DesignView, _super);

  function DesignView() {
    this.render = __bind(this.render, this);
    DesignView.__super__.constructor.apply(this, arguments);
  }

  DesignView.prototype.initialize = function() {
    return this.question = new Question();
  };

  DesignView.prototype.el = $('#content');

  DesignView.prototype.render = function() {
    var templateData;
    templateData = {};
    templateData.types = this.questionTypes;
    $("#content").html(this.template(templateData));
    return this.basicMode();
  };

  DesignView.prototype.template = Handlebars.compile("    <div id='design-view'>      <h3>        Design      </h3>      <small>      <b>Instructions</b>: <p>Use the drop down below to select the type of questions that you will be asking. Click <button>Preview</button> to see what the questions will look like.</p>      <div class='advanced'><b>Advanced: </b><p>Use <img title='repeat' src='images/repeat.png' style='background-color:#DDD'/> to make the question repeatable. If you want to group questions together to form a repeatable block then click <img title='group' src='images/group.png' style='background-color:#DDD'/> between the questions and use the <img title='repeat' src='images/repeat.png' style='background-color:#DDD'/> as before. Ungroup by using <img title='ungroup' src='images/ungroup.png' style='background-color:#DDD'/>.</p>      </div>      </small>      <hr/>      <div id='questions'>        <label for='rootQuestionName'>Name</label>        <input id='rootQuestionName' name='rootQuestionName' type='text'/>      </div>      <label for='element_selector'>Add questions</label>      <select id='element_selector'>        {{#each types}}          <option>{{this}}</option>        {{/each}}      </select>      <button>Add</button><br/>      <button type='button'>Save</button>      <button>Preview</button>      <button>Advanced Mode</button>      <hr/>      <form id='render'></form>      <div id='form_output'></form>    </div>  ");

  DesignView.prototype.questionTypes = ["text", "number", "date", "datetime", "textarea", "select", "hidden"];

  DesignView.prototype.events = {
    "click #design-view button:contains(Add)": "add",
    "click #design-view button[title=group]": "groupClick",
    "click #design-view button[title=ungroup]": "ungroupClick",
    "click #design-view button[title=delete]": "deleteClick",
    "click #design-view button[title=repeat]": "toggleRepeatable",
    "click #design-view button:contains(Preview)": "renderForm",
    "click #design-view button:contains(Show Form Output)": "formDump",
    "click #design-view button:contains(Advanced Mode)": "advancedMode",
    "click #design-view button:contains(Basic Mode)": "basicMode",
    "click #design-view button:contains(Save)": "save"
  };

  DesignView.prototype.save = function() {
    this.question.loadFromDesigner($("#questions"));
    return this.question.save(null, {
      success: function() {
        return Coconut.menuView.render();
      }
    });
  };

  DesignView.prototype.add = function(event) {
    return this.addQuestion({
      type: $(event.target).prev().val()
    });
  };

  DesignView.prototype.loadQuestion = function(questionId) {
    var _this = this;
    this.question = new Question({
      id: questionId
    });
    return this.question.fetch({
      success: function() {
        $('#rootQuestionName').val(_this.question.id);
        return _.each(_this.question.questions(), function(question) {
          return _this.addQuestion(question.attributes);
        });
      }
    });
  };

  DesignView.prototype.addQuestion = function(options) {
    var id, label, repeatable, result, selectOptions, type;
    if (options.questions) {
      alert("Support for editing grouped forms not yet implemented");
    }
    type = options.type;
    id = options.id || Math.ceil(Math.random() * 1000);
    label = options.label || "";
    repeatable = options.repeatable || "";
    selectOptions = options["select-options"] || "option1,option2";
    if ($("#questions").children().length > 0) {
      $("#questions").append("        <button class='advanced' title='group'><img src='images/group.png'/></button>      ");
    }
    result = "      <div data-repeat='false' class='question-definition' id='" + id + "'>        <div class='question-definition-controls'>          <button class='advanced' title='repeat'><img src='images/repeat.png'></button>          <input type='hidden' id=repeatable-" + id + " value='false'></input>          <button title='delete'><img src='images/delete.png'></button>        </div>        <div>Type: " + type + "</div>        <label for='label-" + id + "'>Label</label>        <input type='text' name='label-" + id + "' id='label-" + id + "' value='" + label + "'></input>    ";
    if (type === "select") {
      result += "        <label for='select-options-" + id + "'>Select Options</label>        <textarea name='select-options-" + id + "' id='select-options-" + id + "'>" + selectOptions + "</textarea>      ";
    }
    result += "        <input type='hidden' name='type-" + id + "' id='type-" + id + "' value='" + type + "'></input>        <input type='hidden' name='required-" + id + "' value='false'></input>      </div>    ";
    return $("#questions").append(result);
  };

  DesignView.prototype.groupClick = function(event) {
    var groupDiv;
    groupDiv = $(event.target).closest("button");
    this.group(groupDiv.prev(), groupDiv.next());
    return groupDiv.remove();
  };

  DesignView.prototype.group = function(group1, group2) {
    var group, id, _i, _len, _ref;
    _ref = [group1, group2];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      group = _ref[_i];
      if (group.attr("repeat") === "false" && group.children(".question-definition").length() > 0) {
        this.ungroup(group);
      }
    }
    id = Math.ceil(Math.random() * 1000);
    return group1.add(group2).wrapAll("      <div data-repeat='false' class='question-definition' id='" + id + "'>        <div class='question-definition-controls'>          <button class='advanced' title='repeat'><img src='images/repeat.png'></button>          <input type='hidden' id=repeatable-" + id + " value='false'></input>          <button title='delete'><img src='images/delete.png'></button>          <button class='advanced' title='ungroup'><img src='images/ungroup.png'></button>        </div>      </div>    ");
  };

  DesignView.prototype.ungroupClick = function(event) {
    var controls;
    controls = $(event.target).closest("button").parent();
    return this.ungroup(controls);
  };

  DesignView.prototype.ungroup = function(itemInGroup) {
    var controls, firstQuestionDefinition;
    controls = itemInGroup.parent().children(".question-definition-controls");
    firstQuestionDefinition = itemInGroup.parent().children(".question-definition").first();
    itemInGroup.unwrap();
    controls.remove();
    firstQuestionDefinition.after("      <button class='advanced' title='group'><img src='images/group.png'/></button>    ");
    return itemInGroup;
  };

  DesignView.prototype.deleteClick = function(event) {
    return this.deleteQuestion($(event.target).closest(".question-definition"));
  };

  DesignView.prototype.deleteQuestion = function(question) {
    var surroundingQuestion;
    surroundingQuestion = question.parent(".question-definition");
    if (surroundingQuestion.children(".question-definition").length === 2) {
      this.ungroup(question);
    }
    if (question.next("button").length === 1) {
      question.next("button").remove();
    } else {
      question.prev("button").remove();
    }
    return question.remove();
  };

  DesignView.prototype.toggleRepeatable = function(event) {
    var button, hiddenRepeatableInputElement;
    button = $(event.target).closest("button");
    hiddenRepeatableInputElement = button.next();
    if (hiddenRepeatableInputElement.val() === "false") {
      button.attr("style", 'background-color:green');
      return hiddenRepeatableInputElement.val("true");
    } else {
      button.attr("style", '');
      return hiddenRepeatableInputElement.val("false");
    }
  };

  DesignView.prototype.questions = function() {
    return $('#questions').children();
  };

  DesignView.prototype.toHTMLForm = function() {
    var questionView;
    this.question.loadFromDesigner($("#questions"));
    questionView = new QuestionView({
      model: this.question
    });
    return questionView.toHTMLForm();
  };

  DesignView.prototype.dump = function() {
    return $('#dump').html(this.toJson());
  };

  DesignView.prototype.renderForm = function() {
    $('#render').html(this.toHTMLForm());
    return $('#form_output').html("      <hr/>      <button type='button'>Show Form Output</button><br/>      <textarea id='dump' style='width:400px;height:100px'></textarea>    ");
  };

  DesignView.prototype.formDump = function() {
    return $('#dump').html(JSON.stringify($('form').toObject()));
  };

  DesignView.prototype.advancedMode = function() {
    $('body').removeClass("all-advanced-hidden");
    return $('button:contains(Advanced Mode)').html("Basic Mode");
  };

  DesignView.prototype.basicMode = function() {
    $('body').addClass("all-advanced-hidden");
    return $('button:contains(Basic Mode)').html("Advanced Mode");
  };

  return DesignView;

})(Backbone.View);
