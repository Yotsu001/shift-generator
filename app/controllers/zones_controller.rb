class ZonesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_zone, only: %i[edit update]

  def index
    @zones = Zone.order(:position, :id)
  end

  def new
    @zone = Zone.new(active: true)
  end

  def create
    @zone = Zone.new(zone_params)

    if @zone.save
      redirect_to zones_path, notice: "区を登録しました。"
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @zone.update(zone_params)
      redirect_to zones_path, notice: "区情報を更新しました。"
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_zone
    @zone = Zone.find(params[:id])
  end

  def zone_params
    params.require(:zone).permit(:name, :position, :active)
  end
end
