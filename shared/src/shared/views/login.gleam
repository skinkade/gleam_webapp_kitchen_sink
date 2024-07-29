import formal/form.{type Form}
import gleam/option.{type Option}
import lustre/attribute
import lustre/element
import lustre/element/html
import shared/components/inputs
import shared/dtos/global_view_context.{type GlobalViewContext}
import shared/layouts/base_layout

pub fn login_form(form: Form, error error: Option(String)) {
  html.div([attribute.class("flex justify-center p-4 mt-8")], [
    html.div(
      [attribute.class("min-w-96 max-w-96 flex flex-col justify-center")],
      [
        html.h1([attribute.class("text-xl font-bold mb-2 pl-1")], [
          element.text("User Login"),
        ]),
        html.div([attribute.class("border rounded drop-shadow-sm p-4")], [
          html.form([attribute.method("post")], [
            inputs.username_or_email_input(form),
            inputs.password_input(form, "password"),
            inputs.form_error(error),
            html.div([attribute.class("my-2 flex justify-center")], [
              html.button(
                [attribute.class("btn btn-primary"), attribute.type_("submit")],
                [html.text("Login")],
              ),
            ]),
            html.div([attribute.class("divider")], []),
            html.div(
              [
                attribute.class(
                  "my-4 flex flex-col justify-center items-center",
                ),
              ],
              [
                html.p([attribute.class("mb-2")], [
                  html.text("Need an account?"),
                ]),
                html.a([attribute.href("/register")], [
                  html.button(
                    [
                      attribute.class("btn btn-neutral"),
                      attribute.type_("button"),
                    ],
                    [html.text("Register")],
                  ),
                ]),
              ],
            ),
          ]),
        ]),
      ],
    ),
  ])
}

pub fn login_page(
  ctx: GlobalViewContext,
  form: Form,
  error error: Option(String),
) {
  base_layout.default(ctx, [login_form(form, error)])
}
