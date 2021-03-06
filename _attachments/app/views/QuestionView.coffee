class QuestionView extends Backbone.View
  el: $('#content')

  render: =>
    @el.html "
      <div style='display:none' id='messageText'>
        Saving...
      </div>
      <div id='question-view'>
        <form>
          #{@toHTMLForm(@model)}
        </form>
      </div>
    "
    js2form($('form').get(0), @result.toJSON())
    $("input[name=Tags]").tagit
      availableTags: [
        "complete"
      ]
      onTagChanged: ->
        $("input[name=Tags]").trigger('change')

  events:
    "change #question-view input": "save"
    "change #question-view select": "save"
    "click #question-view button:contains(+)" : "repeat"

  save: ->
    @result.set $('form').toObject()
    $("#messageText").slideDown().fadeOut()
    @result.save()

  repeat: (event) ->
    button = $(event.target)
    newQuestion = button.prev(".question").clone()
    questionID = newQuestion.attr("data-group-id")
    questionID = "" unless questionID?

    # Fix the indexes
    for inputElement in newQuestion.find("input")
      inputElement = $(inputElement)
      name = inputElement.attr("name")
      re = new RegExp("#{questionID}\\[(\\d)\\]")
      newIndex = parseInt(_.last(name.match(re))) + 1
      inputElement.attr("name", name.replace(re,"#{questionID}[#{newIndex}]"))

    button.after(newQuestion.add(button.clone()))
    button.remove()

  toHTMLForm: (questions = @model, groupId) ->
    # Need this because we have recursion later
    questions = [questions] unless questions.length?
    _.map(questions, (question) =>
      if question.repeatable() == "true" then repeatable = "<button>+</button>" else repeatable = ""
      if question.type()? and question.label()? and question.label() != ""
        name = question.label().replace(/[^a-zA-Z0-9 -]/g,"").replace(/[ -]/g,"")
        question_id = question.get("id")
        if question.repeatable() == "true"
          name = name + "[0]"
          question_id = question.get("id") + "-0"
        if groupId?
          name = "group.#{groupId}.#{name}"
        result = "
          <div class='question'>
        "
        unless question.type().match(/hidden/)
          result += "
            <label for='#{question_id}'>#{question.label()}</label>
          "
        if question.type().match(/textarea/)
          result += "
            <textarea name='#{name}' id='#{question_id}'>#{question.value()}</textarea>
          "
        else if question.type().match(/select/)
          result += "
            <select name='#{name}'>
          "
          _.each question.get("select-options").split(/, */), (option) ->
            result += "
              <option>#{option}</option>
            "

          result +=  "
            </select>
          "
        else
          result += "
            <input name='#{name}' id='#{question_id}' type='#{question.type()}' value='#{question.value()}'></input>
          "
        result += "
          </div>
        "
        return result + repeatable
      else
        newGroupId = question_id
        newGroupId = newGroupId + "[0]" if question.repeatable()
        return "<div data-group-id='#{question_id}' class='question group'>" + @toHTMLForm(question.questions(), newGroupId) + "</div>" + repeatable
    ).join("")
