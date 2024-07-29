import formal/form.{type Form}
import gleam/option.{type Option}
import lustre/attribute
import lustre/element
import lustre/element/html
import shared/components/inputs
import shared/dtos/global_view_context.{type GlobalViewContext}
import shared/layouts/base_layout

pub fn register_form(form: Form, error error: Option(String)) {
  html.div([attribute.class("flex justify-center p-4 xs:mt-8 sm:mt-16")], [
    html.div(
      [attribute.class("min-w-96 max-w-96 flex flex-col justify-center")],
      [
        html.h1([attribute.class("text-xl font-bold mb-2 pl-1")], [
          element.text("Register New User"),
        ]),
        html.div([attribute.class("border rounded drop-shadow-sm p-4")], [
          html.form([attribute.method("post")], [
            inputs.email_input(form, "email", disabled: False),
            inputs.form_error(error),
            html.div([attribute.class("my-4 flex justify-center")], [
              //   html.input([attribute.type_("submit"), attribute.value("Submit")]),
              html.button(
                [attribute.class("btn btn-primary"), attribute.type_("submit")],
                [html.text("Register")],
              ),
            ]),
          ]),
        ]),
      ],
    ),
  ])
}

pub fn register_page(
  ctx: GlobalViewContext,
  form: Form,
  error error: Option(String),
) {
  base_layout.default(ctx, [register_form(form, error)])
}

pub fn email_sent() {
  [
    html.div([attribute.class("flex justify-center p-4 xs:mt-8 sm:mt-16")], [
      html.div(
        [attribute.class("min-w-96 max-w-96 flex flex-col justify-center")],
        [
          html.h1([attribute.class("text-xl font-bold mb-2 pl-1")], [
            element.text("Register"),
          ]),
          html.div([attribute.class("border rounded drop-shadow-sm p-4")], [
            html.p([], [
              html.text("A registration link has been sent to your email."),
            ]),
          ]),
        ],
      ),
    ]),
  ]
}

pub fn email_sent_page(ctx: GlobalViewContext) {
  base_layout.default(ctx, email_sent())
}

pub fn confirm_form(form: Form, error: Option(String)) {
  html.div([attribute.class("flex justify-center p-4 xs:mt-8 sm:mt-16")], [
    html.div(
      [attribute.class("min-w-96 max-w-96 flex flex-col justify-center")],
      [
        html.h1([attribute.class("text-xl font-bold mb-2 pl-1")], [
          element.text("Register New User"),
        ]),
        html.div([attribute.class("border rounded drop-shadow-sm p-4")], [
          html.form([attribute.method("post")], [
            inputs.email_input(form, "email", disabled: True),
            inputs.username_input(form, "username"),
            inputs.password_input(form, "password"),
            html.input([
              attribute.type_("hidden"),
              attribute.name("token"),
              attribute.value(form.value(form, "token")),
            ]),
            inputs.form_error(error),
            html.div([attribute.class("my-4 flex justify-center")], [
              //   html.input([attribute.type_("submit"), attribute.value("Submit")]),
              html.button(
                [attribute.class("btn btn-primary"), attribute.type_("submit")],
                [html.text("Register")],
              ),
            ]),
          ]),
        ]),
      ],
    ),
  ])
}

pub fn confirm_page(
  ctx: GlobalViewContext,
  form: Form,
  error error: Option(String),
) {
  base_layout.default(ctx, [confirm_form(form, error)])
}

pub fn invalid_or_expired_confirmation_token(ctx: GlobalViewContext) {
  base_layout.default(ctx, [
    html.div([attribute.class("flex justify-center p-4 xs:mt-8 sm:mt-16")], [
      html.div(
        [attribute.class("min-w-96 max-w-96 flex flex-col justify-center")],
        [
          html.h1([attribute.class("text-xl font-bold mb-2 pl-1")], [
            element.text("Invalid Registration Link"),
          ]),
          html.div([attribute.class("border rounded drop-shadow-sm p-4")], [
            html.div(
              [
                attribute.class(
                  "alert alert-warning py-2 px-4 text-sm rounded text-center flex flex-col",
                ),
                attribute.role("alert"),
              ],
              [
                html.p([attribute.class("font-bold")], [
                  html.text("This registration link is invalid or has expired."),
                ]),
              ],
            ),
          ]),
        ],
      ),
    ]),
  ])
}
