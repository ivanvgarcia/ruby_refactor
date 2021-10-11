class PostController < ApplicationController

  def show
    @post = Post.active.find_by(slug: params[:slug])

    @author = @post.author

    render 'errors/404.html', status: :not_found unless @post.present?

    redirect_to posts_path if @author.inactive?

    render :show
  end

  def index
    @posts = Post.active.include(:author)

    find_post_categories

    find_before_date_posts

    find_search_results

    @posts = @posts.page(params[:page]).per(20)

    redirect_to blog_index_path if @posts.count.zero?

    render :index
  end

  def breaking_news
    @posts = Post.active.breaking.page(params[:page]).per(20)
  end

  def update
    redirect_to posts_path unless current_user.admin?

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

  private

  def post_params
    params[:post].permit!
  end

  def find_categories
    Category.visible.all
  end

  def find_post_categories
    @posts_categories = []
    @posts.each do |post|
      @posts_categories << post.category if find_categories.include?(post.category)
    end
  end

  def find_before_date_posts
    @posts = Post.active.where('created_at > ?', params[:before_date]) if params[:before_date]
  end

  def find_search_results
    return unless params[:q]

    @q = Posts.active.include(:author).ransack(params[:q])
    @posts = @q.result
  end
end
