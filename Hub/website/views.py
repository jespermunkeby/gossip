from flask import Blueprint, render_template, request, flash
from .settings.settings import set_config


def define_views(add_post, delete_post):
    views = Blueprint("views", __name__)

    @views.route("/")
    def home():
        return render_template("home.html")

    @views.route("/settings", methods=["GET", "POST"])
    def settings():
        if request.method == "POST":
            data = request.form.to_dict()
            set_config(data)
            flash("Settings updated!", category="success")

        return render_template("settings.html")

    @views.route("/posts", methods=["GET", "POST"])
    def status():
        if request.method == "POST":
            form = request.form.to_dict()
            if form['form'] == 'delete':
                delete_post(form['post_id'])
            elif form['form'] == 'new_post':
                add_post(form['post_content'].encode())
        return render_template("posts.html")

    return views
