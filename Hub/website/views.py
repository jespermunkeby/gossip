from flask import Blueprint, render_template, request, flash
from .settings.settings import BbSettings

views = Blueprint("views", __name__)

@views.route("/")
def home():
    return render_template("home.html")

@views.route("/settings", methods=["GET", "POST"])
def settings():
    if request.method == "POST":
        data = request.form.to_dict()
        config = BbSettings()
        config.set_all(data)
        config.write()
        flash("Settings updated!", category="success")
        
    return render_template("settings.html")

@views.route("/posts")
def status():
    return render_template("posts.html")
