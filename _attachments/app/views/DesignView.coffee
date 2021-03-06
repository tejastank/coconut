class DesignView extends Backbone.View
  initialize: ->
    @question = new Question()

  el: $('#content')

  render: =>
    templateData = {}
    templateData.types = @questionTypes
    $("#content").html(this.template(templateData))
    @basicMode()

  template: Handlebars.compile "
    <div id='design-view'>
      <h3>
        Design
      </h3>
      <small>
      <b>Instructions</b>: <p>Use the drop down below to select the type of questions that you will be asking. Click <button>Preview</button> to see what the questions will look like.</p>
      <div class='advanced'><b>Advanced: </b><p>Use <img title='repeat' src='images/repeat.png' style='background-color:#DDD'/> to make the question repeatable. If you want to group questions together to form a repeatable block then click <img title='group' src='images/group.png' style='background-color:#DDD'/> between the questions and use the <img title='repeat' src='images/repeat.png' style='background-color:#DDD'/> as before. Ungroup by using <img title='ungroup' src='images/ungroup.png' style='background-color:#DDD'/>.</p>
      </div>
      </small>
      <hr/>

      <div id='questions'>
        <label for='rootQuestionName'>Name</label>
        <input id='rootQuestionName' name='rootQuestionName' type='text'/>
      </div>
      <label for='element_selector'>Add questions</label>
      <select id='element_selector'>
        {{#each types}}
          <option>{{this}}</option>
        {{/each}}
      </select>
      <button>Add</button><br/>
      <button type='button'>Save</button>
      <button>Preview</button>
      <button>Advanced Mode</button>
      <hr/>
      <form id='render'></form>
      <div id='form_output'></form>
    </div>
  "

  questionTypes: ["text","number","date","datetime", "textarea", "select", "hidden"]

  events:
    "click #design-view button:contains(Add)": "add"
    "click #design-view button[title=group]": "groupClick"
    "click #design-view button[title=ungroup]": "ungroupClick"
    "click #design-view button[title=delete]": "deleteClick"
    "click #design-view button[title=repeat]": "toggleRepeatable"
    "click #design-view button:contains(Preview)" : "renderForm"
    "click #design-view button:contains(Show Form Output)" : "formDump"
    "click #design-view button:contains(Advanced Mode)" : "advancedMode"
    "click #design-view button:contains(Basic Mode)" : "basicMode"
    "click #design-view button:contains(Save)" : "save"

  save: ->
    @question.loadFromDesigner $("#questions")
    @question.save null,
      success: ->
        Coconut.menuView.render()

  add: (event) ->
    @addQuestion
      type : $(event.target).prev().val()

  loadQuestion: (questionId) ->
    @question = new Question
      id: questionId
    @question.fetch
      success: =>
        $('#rootQuestionName').val @question.id
        _.each @question.questions(), (question) =>
          @addQuestion question.attributes

  addQuestion: (options) ->
    alert "Support for editing grouped forms not yet implemented" if options.questions
    type = options.type
    id = options.id || Math.ceil(Math.random()*1000)
    label = options.label || ""
    repeatable = options.repeatable || ""
    selectOptions = options["select-options"] || "option1,option2"

    if $("#questions").children().length > 0
      $("#questions").append "
        <button class='advanced' title='group'><img src='images/group.png'/></button>
      "
    result = "
      <div data-repeat='false' class='question-definition' id='#{id}'>
        <div class='question-definition-controls'>
          <button class='advanced' title='repeat'><img src='images/repeat.png'></button>
          <input type='hidden' id=repeatable-#{id} value='false'></input>
          <button title='delete'><img src='images/delete.png'></button>
        </div>
        <div>Type: #{type}</div>
        <label for='label-#{id}'>Label</label>
        <input type='text' name='label-#{id}' id='label-#{id}' value='#{label}'></input>
    "
    if type is "select"
      result += "
        <label for='select-options-#{id}'>Select Options</label>
        <textarea name='select-options-#{id}' id='select-options-#{id}'>#{selectOptions}</textarea>
      "

    result += "
        <input type='hidden' name='type-#{id}' id='type-#{id}' value='#{type}'></input>
        <input type='hidden' name='required-#{id}' value='false'></input>
      </div>
    "

    $("#questions").append result

  groupClick: (event) ->
    groupDiv = $(event.target).closest("button")
    @group(groupDiv.prev(), groupDiv.next())
    groupDiv.remove()

  group: (group1,group2) ->
    for group in [group1,group2]
      if group.attr("repeat") == "false" and group.children(".question-definition").length() > 0
        @ungroup(group)
    id = Math.ceil(Math.random()*1000)
    group1.add(group2).wrapAll "
      <div data-repeat='false' class='question-definition' id='#{id}'>
        <div class='question-definition-controls'>
          <button class='advanced' title='repeat'><img src='images/repeat.png'></button>
          <input type='hidden' id=repeatable-#{id} value='false'></input>
          <button title='delete'><img src='images/delete.png'></button>
          <button class='advanced' title='ungroup'><img src='images/ungroup.png'></button>
        </div>
      </div>
    "

  ungroupClick: (event) ->
    controls = $(event.target).closest("button").parent()
    @ungroup controls

  ungroup: (itemInGroup) ->
    controls = itemInGroup.parent().children(".question-definition-controls")
    firstQuestionDefinition = itemInGroup.parent().children(".question-definition").first()
    itemInGroup.unwrap()
    controls.remove()
    firstQuestionDefinition.after "
      <button class='advanced' title='group'><img src='images/group.png'/></button>
    "
    itemInGroup

  deleteClick: (event) ->
    @deleteQuestion($(event.target).closest(".question-definition"))


  deleteQuestion: (question) ->
    surroundingQuestion = question.parent(".question-definition")
    if surroundingQuestion.children(".question-definition").length == 2
      @ungroup(question)

    # Remove Group/Ungroup buttons
    if question.next("button").length == 1
      question.next("button").remove()
    else
      question.prev("button").remove()

    # Removes the question-definition div
    question.remove()


  toggleRepeatable: (event) ->
    button = $(event.target).closest("button")

    hiddenRepeatableInputElement = button.next()
    if hiddenRepeatableInputElement.val() == "false"
      button.attr("style",'background-color:green')
      hiddenRepeatableInputElement.val("true")
    else
      button.attr("style",'')
      hiddenRepeatableInputElement.val("false")

  questions: ->
    return $('#questions').children()

  toHTMLForm: ->
    @question.loadFromDesigner($("#questions"))
    questionView = new QuestionView(model: @question)
    questionView.toHTMLForm()

  dump: ->
    $('#dump').html(@toJson())

  renderForm: ->
    $('#render').html @toHTMLForm()
    $('#form_output').html "
      <hr/>
      <button type='button'>Show Form Output</button><br/>
      <textarea id='dump' style='width:400px;height:100px'></textarea>
    "

  formDump: ->
    $('#dump').html(JSON.stringify($('form').toObject()))

  advancedMode:->
    $('body').removeClass("all-advanced-hidden")
    $('button:contains(Advanced Mode)').html "Basic Mode"

  basicMode:->
    $('body').addClass("all-advanced-hidden")
    $('button:contains(Basic Mode)').html "Advanced Mode"

