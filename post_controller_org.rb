class PostController < ApplicationController
  def show
    @post = Post.active.find_by(slug: params[:slug])
    @author = @post.author

    if !@post.present?
      render "errors/404.html", status: :not_found
    end

    if @author.inactive?
      redirect_to posts_path
    end

    render :show
  end

  def index
    @posts = Post.active.include(:author)
    @posts_categories = []
    @posts.each do |post|
      if get_categories.include?(post.category)
        @posts_categories << post.category
      end
    end
    if params[:before_date]
      @posts = Post.active.where("created_at > ?", params[:before_date])
    end
    if params[:q]
      @q = Posts.active.include(:author).ransack(params[:q])
      @posts = @q.result
    end
    @posts = @posts.page(params[:page]).per(20)
    if @posts.count == 0
      redirect_to blog_index_path
    end

    render :index
  end

  def breaking_news
    @posts = Post.active.breaking.page(params[:page]).per(20)
  end

  def update
    redirect_to posts_path if !current_user.admin?

    @post = Post.active.find(params[:id])

    if @post.update(post_params)
      redirection_to :index
    else
      render :update
    end
  end

  def preview
    @post = Post.active.find(params[:id])
  end

  def post_params
    params[:post].permit!
  end

  def get_categories
    Category.visible.all
  end
end