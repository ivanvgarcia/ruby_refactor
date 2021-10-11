class Admin::AdminPostsController < InheritedResources::Base
  layout 'admin'
  before_filter :require_login
  before_action :create_post_menu, only: %i[show new create]
  before_action :find_post, only: %i[show update destroy]
  before_action :find_sections, only: %i[show new]
  before_action :find_branches, only: %i[index show new create]
  load_and_authorize_resource

  def index
    @posts = Post.order('created_at DESC')
    find_user_posts
    @posts = @posts.paginate(page: params[:page], per_page: 20)
    find_post_categories
  end

  def show
    @date = @post.created_at
    @blocks = @post.blocks.order(:degree)
  end

  def refresh
    @posts = Post.order('id DESC')
    render layout: false
  end

  def new
    @post = Post.new
  end

  def create
    @post = Post.new(params[:post].merge(user_id: current_user.id))
    @sections = Branch.find(params[:post][:branch_id]).sections.order(:degree)
    if @post.save
      expire_page controller: 'static', action: 'index' if @post.status == 'published'
      redirect_to admin_post_path(@post)
    else
      render 'new'
    end
  end

  def update
    @post.update_attributes(params[:post].merge(created_at: "#{params[:date_year]}-#{params[:date_month]}-#{params[:date_day]} #{params[:date_hour]}:#{params[:date_minute]}:00"))

    params[:text]&.each do |itm|
      Blocktext.find(itm[0]).update_attributes(text: itm[1])
    end

    @errors = @post.errors.full_messages

    respond_to do |format|
      format.html { redirect_to :back }
      format.js
    end
  end

  def destroy
    @post.comment_threads.each(&:delete)
    @post.delete
    respond_to do |format|
      format.html { redirect_to admin_posts_path, :flash => { :success => "#{t 'articles.controllers.destroy.flash.success', :name => @post.name}"} }
      format.js
    end
  end

  def upload
    if @post.update_attributes(photo: params[:file])
      render json: { 'success' => true, 'url' => "#{@post.photo.url(:middle)}#{@post.photo.updated_at}" }
    else
      render json: { 'error' => @post.errors }
    end
  end

  def remove
    Post.find(params[:id]).update_attributes(photo: nil)
    render text: nil
  end

  def flush
    params[:items].each do |itm|
      Post.find(itm).destroy
    end
    render text: 'success'
  end

  def search
    @posts = Post.where('name LIKE ?', '%' + params[:request] + '%')
    find_user_posts
    if @posts.empty?
      render text: 0
    else
      render layout: false
    end
  end

  def selector
    @posts = Post.order('id DESC')
    find_user_posts
    @posts = @posts.where('status = ?', params[:status]) if params[:status] != 'all'
    @posts = @posts.where('branch_id = ?', params[:branch]) if params[:branch] != 'all'
    render layout: false
  end

  private

  def find_categories
    Category.visible.all
  end

  def find_post
    @post = Post.find(params[:id])
  end

  def admin?
    current_user.role == 'admin'
  end

  def editor?
    current_user.role == 'editor'
  end

  def find_user_posts
    @posts = @posts.where('user_id = ?', current_user) unless admin?
  end

  def delete_branches
    @branches = @branches&.delete_if { |x| !current_user.access_branches.include?(x.id) } if editor?
  end

  def find_branches
    @branches = Branch.order(:degree)
    delete_branches
  end

  def create_post_menu
    @menu_post_create = true
  end

  def find_post_categories
    @posts_categories = []
    @posts.each do |post|
      @posts_categories << post.category if find_categories.include?(post.category)
    end
  end

  def find_sections
    @sections = @post.branch.sections.order(:degree)
  end
end
