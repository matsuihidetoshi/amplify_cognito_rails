module Api
  module V1
    class NotesController < ApplicationController
      skip_before_action :verify_authenticity_token
      
      before_action :set_note, only: [:show, :update, :destroy]
      before_action :verify_jwt_token

      def index
        notes = Note.search(search_params)
        length = notes.length
        notes = notes.page(params[:page]).per(params[:per]).order(created_at: :desc)
        render json: { status: 'SUCCESS', message: 'Loaded notes', data: notes, length: length }
      end

      def show
        note = Note.find(params[:id])
        render json: { status: 'SUCCESS', message: 'Loaded the note', data: note }
      end

      def create
        note = Note.new(note_params)
        if note.save
          render json: { status: 'SUCCESS', data: note }
        else
          render json: { status: 'ERROR', data: note.errors }
        end
      end

      def update
        if @note.update(note_params)
          render json: { status: 'SUCCESS', message: 'Updated the note', data: @note }
        else
          render json: { status: 'SUCCESS', message: 'Not updated', data: @note.errors }
        end
      end

      def destroy
        @note.destroy
        render json: { status: 'SUCCESS', message: 'Deleted the note', data: @note }
      end

      def authenticate
        render json: { status: 'SUCCESS', message: 'Verified', data: @claims}
      end

      private

      def set_note
        @note = Note.find(params[:id])
      end

      def note_params
        params.require(:note).permit(:title, :content, :user)
      end

      def search_params
        params.fetch(:search, {}).permit(:title_like, :created_from, :created_to, :content_like)
      end

      def verify_jwt_token
        cognito = CognitoService.new(
          ENV['COGNITOTEST_REGION'],
          ENV['COGNITOTEST_USERPOOL_ID'],
          ENV['COGNITOTEST_APP_CLIENT_ID']
        )

        cognito.verify(params[:token])

        render status: 401, json: { status: 'ERROR', message: cognito.detail } unless cognito.verified? else @claims = cognito.detail
      end
    end
  end
end
