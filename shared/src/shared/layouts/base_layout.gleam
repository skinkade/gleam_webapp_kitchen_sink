import gleam/option.{None, Some}
import gleroglero/solid
import lustre/attribute.{attribute}
import lustre/element.{element}
import lustre/element/html.{text}
import shared/dtos/global_view_context.{type GlobalViewContext}
import shared/dtos/users

pub fn base_html(ctx: GlobalViewContext, children) {
  html.html([attribute("lang", "en")], [
    html.head([], [
      html.meta([attribute.attribute("charset", "UTF-8")]),
      html.meta([
        attribute.attribute("name", "viewport"),
        attribute.attribute("content", "width=device-width, initial-scale=1.0"),
      ]),
      html.title([], case ctx.page_title == ctx.app_name {
        True -> ctx.app_name
        False -> ctx.page_title <> " | " <> ctx.app_name
      }),
      html.link([
        attribute.rel("stylesheet"),
        attribute.href("/static/style.css"),
      ]),
    ]),
    html.body([], children),
  ])
  |> element.to_document_string_builder()
}

pub fn default(ctx: GlobalViewContext, content) {
  let auth_element = case ctx.user {
    Some(user) ->
      html.div([attribute.class("dropdown")], [
        html.div(
          [
            attribute.class("btn m-1"),
            attribute.role("button"),
            attribute("tabindex", "0"),
          ],
          [text(users.user_display_text(user))],
        ),
        html.ul(
          [
            attribute.class(
              "dropdown-content menu bg-base-100 rounded-box z-[1] w-52 p-2 shadow",
            ),
            attribute("tabindex", "0"),
          ],
          [html.li([], [html.a([], [text("Logout")])])],
        ),
      ])
    None ->
      html.div([attribute.class("flex-0")], [
        html.a([attribute.href("/login")], [
          html.button([attribute.class("btn"), attribute.type_("button")], [
            html.text("Login"),
          ]),
        ]),
      ])
  }

  base_html(ctx, [
    html.div([attribute.class("drawer")], [
      html.input([
        attribute.class("drawer-toggle"),
        attribute.type_("checkbox"),
        attribute.id("page-drawer"),
      ]),
      html.div([attribute.class("drawer-content")], [
        html.header(
          [
            attribute.class(
              "bg-base-100 text-base-content sticky top-0 z-30 flex h-16 w-full justify-center bg-opacity-90 backdrop-blur transition-shadow",
            ),
          ],
          [
            html.nav([attribute.class("navbar w-full")], [
              html.div([attribute.class("flex flex-1 md:gap-1 lg:gap-2")], [
                html.label(
                  [
                    attribute.class("btn btn-neutral drawer-button"),
                    attribute.for("page-drawer"),
                  ],
                  [text(ctx.app_name)],
                ),
              ]),
              html.div([attribute.class("flex-0")], [auth_element]),
            ]),
          ],
        ),
        html.main([attribute.class("container")], content),
      ]),
      html.div([attribute.class("drawer-side mt-16")], [
        html.label(
          [
            attribute.class("drawer-overlay"),
            attribute("aria-label", "close sidebar"),
            attribute.for("page-drawer"),
          ],
          [],
        ),
        html.ul(
          [
            attribute.class(
              "menu bg-base-200 text-base-content min-h-full w-80 p-4",
            ),
          ],
          [
            html.li([], [
              html.a([attribute.href("/")], [
                html.div([attribute.class("h-4 w-4")], [solid.home()]),
                text("Home"),
              ]),
            ]),
            html.li([], [html.a([], [text("Something Else")])]),
          ],
        ),
      ]),
    ]),
  ])
}
