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

@views.route("/posts", methods=["GET", "POST"])
def status():
    if request.method == "POST":
        keys = list(request.form.to_dict().keys())
        if len(keys) < 0:
            return
        elif keys[0].startswith("delete"):
            print("delete: " + str(keys[0]))
    return render_template("posts.html")
