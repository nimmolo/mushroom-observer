# create and edit Glossary terms
class GlossaryController < ApplicationController
  before_action :login_required, except: [
    :index,
    :show,
    :show_past_glossary_term,
    :show_glossary_term # aliased
  ]

  def show
    store_location
    @glossary_term = GlossaryTerm.find(params[:id].to_s)
    @canonical_url = "#{MO.http_domain}/glossary/#{@glossary_term.id}"
    @layout = calc_layout_params
    @objects = @glossary_term.images
  end

  alias_method :show_glossary_term, :show

  def index
    store_location
    @glossary_terms = GlossaryTerm.all.order(:name)
  end

  def new
    @copyright_holder = @user.name
    @copyright_year = Time.now.utc.year
    @upload_license_id = @user.license_id
    @licenses = License.current_names_and_ids(@user.license)
  end

  alias_method :create_glossary_term, :new
  alias_method :glossary_term_get, :new

  def create
    @glossary_term = \
      GlossaryTerm.new(user: @user, name: params[:glossary_term][:name],
                       description: params[:glossary_term][:description])
    @glossary_term.add_image(process_image(image_args))
    @glossary_term.save
    # redirect_to(
    #   action: :show,
    #   id: glossary_term.id
    # )
    redirect_to glossary_path(@glossary_term.id)
  end

  alias_method :glossary_term_post, :create

  private

  def image_args
    {
      copyright_holder: params[:copyright_holder],
      when: Time.local(params[:date][:copyright_year]).utc,
      license: License.safe_find(params[:upload][:license_id]),
      user: @user,
      image: params[:glossary_term][:upload_image]
    }
  end

  def process_image(args)
    image = nil
    name = nil
    upload = args[:image]
    if upload.blank?
      name = upload.original_filename.force_encoding("utf-8") if
        upload.respond_to?(:original_filename)

      image = Image.new(args)
      save_or_flash(image)
    end
    image
  end

  def save_or_flash(image)
    if !image.save
      flash_object_errors(image)
    elsif !image.process_image
      logger.error("Unable to upload image")
      name = image.original_name
      name = "???" if name.empty?
      flash_error(:runtime_image_invalid_image.t(name: name))
      flash_object_errors(image)
    else
      name = image.original_name
      name = "##{image.id}" if name.empty?
      flash_notice(:runtime_image_uploaded_image.t(name: name))
    end
  end

  def edit # :norobots:
    # Expand to any MO user,
    # but make them owned and editable only by that user or an admin
    @glossary_term = GlossaryTerm.find(params[:id].to_s)
  end

  alias_method :edit_glossary_term, :edit

  def update
    @glossary_term = GlossaryTerm.find(params[:id].to_s)
    @glossary_term.attributes = params[:glossary_term].
                               permit(:name, :description)
    @glossary_term.user = @user
    @glossary_term.save
    # redirect_to(
    #   action: :show,
    #   id: glossary_term.id
    # )
    redirect_to glossary_path(@glossary_term.id)
  end

  # no alias needed

  # Show past version of GlossaryTerm.
  # Accessible only from show_glossary_term page.
  def show_past_glossary_term # :prefetch: :norobots:
    pass_query_params
    store_location
    if @glossary_term = find_or_goto_index(GlossaryTerm, params[:id].to_s)
      if params[:version]
        @glossary_term.revert_to(params[:version].to_i)
      else
        flash_error(:show_past_location_no_version.t)
        # redirect_to(
        #   action: :show,
        #   id: glossary_term.id
        # )
        redirect_to glossary_path(@glossary_term.id)
      end
    end
  end
end
