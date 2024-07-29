import formal/form.{type Form}
import gleam/option.{type Option, None, Some}
import gleroglero/solid
import lustre/attribute.{type Attribute, attribute}
import lustre/element.{type Element, element}
import lustre/element/html.{text}

pub fn field_error(form, name) {
  let error_element = case form.field_state(form, name) {
    Ok(_) -> element.none()
    Error(message) ->
      html.div(
        [
          attribute.class(
            "alert alert-error py-2 px-4 text-sm rounded text-center",
          ),
          attribute.role("alert"),
        ],
        [html.span([], [text(message)])],
      )
  }

  html.div([attribute.class("min-h-8 mb-2")], [error_element])
}

pub fn form_field(
  form: Form,
  name name: String,
  kind kind: String,
  title title: String,
  attributes additional_attributes: List(Attribute(a)),
) -> Element(a) {
  html.label([], [
    html.div([], [element.text(title)]),
    html.input([
      attribute.type_(kind),
      attribute.name(name),
      attribute.value(form.value(form, name)),
      ..additional_attributes
    ]),
    field_error(form, name),
  ])
}

pub fn form_error(error: Option(String)) {
  let error_element = case error {
    None -> element.none()
    Some(message) ->
      html.div(
        [
          attribute.class(
            "alert alert-error py-2 px-4 text-sm rounded text-center",
          ),
          attribute.role("alert"),
        ],
        [html.span([], [text(message)])],
      )
  }

  html.div([attribute.class("min-h-8 mb-2")], [error_element])
}

pub fn email_input(form: Form, name: String, disabled disabled: Bool) {
  html.div([attribute.class("mb-2")], [
    html.label([attribute.for(name), attribute.class("font-bold mb-2 pl-1")], [
      element.text("Email"),
      html.div(
        [attribute.class("input input-bordered flex items-center gap-4 mb-2")],
        [
          html.div([attribute.class("h-4 w-4")], [solid.at_symbol()]),
          html.input([
            attribute.placeholder("awesomeperson@example.com"),
            attribute.class("grow"),
            attribute.type_("email"),
            attribute.name(name),
            attribute.required(True),
            attribute.value(form.value(form, name)),
            attribute.autocomplete("off"),
            attribute.disabled(disabled),
          ]),
        ],
      ),
    ]),
    field_error(form, name),
  ])
}

pub fn username_input(form: Form, name: String) {
  html.div([attribute.class("mb-2")], [
    html.label([attribute.for(name), attribute.class("font-bold mb-2 pl-1")], [
      element.text("Username"),
      html.div(
        [attribute.class("input input-bordered flex items-center gap-4 mb-2")],
        [
          html.div([attribute.class("h-4 w-4")], [solid.user()]),
          html.input([
            attribute.placeholder("awesomeperson"),
            attribute.class("grow"),
            attribute.type_("text"),
            attribute.name(name),
            attribute.required(True),
            attribute.value(form.value(form, name)),
            attribute.autocomplete("off"),
          ]),
        ],
      ),
    ]),
    field_error(form, name),
  ])
}

pub fn username_or_email_input(form: Form) {
  let name = "username_or_email"
  html.div([attribute.class("mb-2")], [
    html.label([attribute.for(name), attribute.class("font-bold mb-2 pl-1")], [
      element.text("Username or Email"),
      html.div(
        [attribute.class("input input-bordered flex items-center gap-4 mb-2")],
        [
          html.div([attribute.class("h-4 w-4")], [solid.user()]),
          html.input([
            attribute.placeholder("awesomeperson(@example.com)"),
            attribute.class("grow"),
            attribute.type_("text"),
            attribute.name(name),
            attribute.required(True),
            attribute.value(form.value(form, name)),
            attribute.autocomplete("off"),
          ]),
        ],
      ),
    ]),
    field_error(form, name),
  ])
}

pub fn password_input(form: Form, name: String) {
  html.div([attribute.class("mb-2")], [
    html.label([attribute.for(name), attribute.class("font-bold mb-2 pl-1")], [
      element.text("Password"),
      html.div(
        [attribute.class("input input-bordered flex items-center gap-4 mb-2")],
        [
          html.div([attribute.class("h-4 w-4")], [solid.lock_closed()]),
          html.input([
            attribute.placeholder("************"),
            attribute.class("grow"),
            attribute.type_("password"),
            attribute.name(name),
            // attribute.value(form.value(form, name)),
            attribute.autocomplete("off"),
            attribute.required(True),
            // attribute("minlength", "12"),
            attribute("maxlength", "50"),
          ]),
        ],
      ),
    ]),
    field_error(form, name),
  ])
}
