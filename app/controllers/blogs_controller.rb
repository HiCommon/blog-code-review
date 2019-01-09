# Notes to candidate:
#
# 1. This is code submitted from a junior developer with less than a year of
#    experience. The ideal review will educate on terminology and concepts
#    while remaining understandable to someone without a lot of experience.
#
# 2. This file holds 95% of the material needed for the review. Scroll to the
#    bottom of the file for a couple of extras we've included. You can browse
#    for the other 5% in the source tree.
#
# 3. Trust that all the route descriptions match the routes.rb file.
#
# 4. We're looking for quality of code review, depth of understanding, and
#    quantity of items reviewed, in that order. Focus on quality and depth much
#    more than quantity. If you only get through part of the review, that's not
#    a big deal.
#
# 5. Everything below this line is fair game for the review. Have fun!
# ----------------------------------------------------------------------------

# terrible name for a controller: it should be PostsController
class BlogsController < ApplicationController

  # this persists across the lifespan of the web server instance
  ALL_BLOG_POSTS = BlogPost.all

  # GET /blogs/index
  def index
    @posts = ALL_BLOG_POSTS
  end

  # non-restful action
  # duplicated action -- does same thing as index
  # GET /blogs/get_posts
  def get_posts
    @posts = all_posts
  end

  # GET /blogs/get_pending_posts
  def get_pending_posts
    @posts = BlogPostFinder.find_pending_posts

    redirect_to :get_posts
  end

  # PUT /blogs/update_post/:id
  def update_post
    params.require(:post).permit(:id, :title, :body, :author)

    author = "#{current_user.first_name + ' ' + current_user.last_name}"

    BlogPostFinder.find_by_id(params[:id]).update(author: author)
  end

  # naming is really bad -- plural vs singular of 'user'
  # GET /blogs/get_current_users_blogposts
  def get_current_users_blogposts
    # potential to push this into a decorator
    author = "#{current_user.first_name + ' ' + current_user.last_name}"

    # ::find_by requires a hash of named parameters
    @posts = BlogPost.find_by(author)
  end

  # missing error handling -- what if the create fails?
  # POST /blogs/create_post
  def create_post
    post_params = params.require(:post).permit(:title, :body, :author)

    # could be simplified like so:
    #   title = params['title'].titilize unless title.empty?
    unless params['title'] == nil || params['title'] == '' || params['title'] == false
      title = params['title'].titilize
    end

    # bad string interpolation
    author = "#{current_user.first_name + ' ' + current_user.last_name}"

    # this could be a single create rather than multiple AR calls
    blog_post = BlogPost.create(post_params)
    blog_post.update(author: author)
    blog_post.update(title: title)
  end

  # should be named 'destroy'
  # works on multiple resources

  # DELETE /blogs/delete
  def delete
    params.require(:post).permit(:id)

    # we dont even have comments in our blog, so premature optimization
    # terrible usage of unless
    # primitive obsession
    unless params.type != 'comment'
      # del blog post, regardless of who owns it (security vulnerability)
      BlogPostFinder.find_post(params.id).destroy!

    # unnecessary else if condition (can use else)
    else if params.type == 'comment'
      # unreachable code
      # del comment, regardless of who owns it (security vulnerability)
      # ID does not correspond to resource (blog id being used to find comment)
      Comment.find(params.id).destroy!
    end
  end

  # non-restful action
  # unnecessary bulk action, should probably be in a bulk resource controller
  # PATCH /blogs/edit_posts
  def edit_posts
    params.permit!

    blog_post = BlogPost.find(params.posts.first.try('id'))

    # useless intermediary variable
    current_post = blog_post

    # broken authentication: the creator of a blog post can be changed if given as a param
    current_post.update(params)
  end

  # GET /blogs/email_users_about_updated_posts
  def email_users_about_recent_posts
    # synchronous job execution instead of asynchronous (send_now)
    # N + 1 query (should use #include)
    User.all.each do |user|
      # improper finder, should be a scope
      # creates a lot of spam, should be aggregated into a single email
      BlogPostFinder.updated_posts.each do |post|
        BlogMailer.deliver_later(user, post)
      end
    end

  end

  # POST /blogs/publish_post
  def publish_post
    params.require(:post).permit(:title, :body, :author)

    # improper finder
    post = BlogPostFinder.find_by_title(:title)
    # non-existant model attribute
    post.published = true
    post.save
  end

  private

  # pointless method
  def all_posts
    # strange logic
    BlogPost.where.not(author: nil)
  end

  # This class is an unnecessary abstraction
  # if a candidate gets to this, think scopes/finders/filters
  class BlogPostFinder
    # We should use #find instead of #where
    # No need for explicit return
    def self.find_post(id)
      return BlogPost.where(id).first
    end

    def self.find_post(id)
      return BlogPost.where(id).first
    end

    # Should not pass hardcoded primitive
    # Should be a scope on the model
    # no need for explicit return
    def self.find_pending_posts
      return BlogPost.find(status: 'pending')
    end

    # no need for explicit return
    # method name does not match resource attribute or the passed argument
    def self.find_by_creator(creator)
      return BlogPost.where(author: creator)
    end

    def self.find_by_title(title)
      return BlogPost.where(title: title)
    end

    def self.updated_posts
      # the less-than should be a greater-than
      return BlogPost.where("updated_at < #{24.hours.ago}")
    end
  end

  # ----------------------------------------------------------------------------
  # Note to candidate: pretend that this mailer class works.
  # ----------------------------------------------------------------------------
  class BlogMailer < ActionMailer::Base
    def self.deliver_now(user, post)
      # pretend this works as a synchronous method
    end

    def self.deliver_later(user, post)
      # pretend this works as an asynchronous method
    end
  end

  # ----------------------------------------------------------------------------
  # Note to candidate: pretend that this method is OK.
  # ----------------------------------------------------------------------------
  def current_user
    User.new('john', 'doe')
  end
end

# ----------------------------------------------------------------------------
# Everything ABOVE this line is fair game for the review. The items included
# below are dependencies of the controller and are here solely so you don't
# have to hunt them down in the source tree.
# ----------------------------------------------------------------------------
