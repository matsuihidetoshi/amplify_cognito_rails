module Api
  module V1
    class NotesController < ApplicationController
      skip_before_action :verify_authenticity_token
      
      before_action :set_note, only: [:show, :update, :destroy]

      def index
        notes = Note.order(created_at: :desc)
        render json: { status: 'SUCCESS', message: 'Loaded notes', data: notes }
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
        render json: { status: 'SUCCESS', message: AuthenticationService.new.authenticate(params[:token])}
      end

      private

      def set_note
        @note = Note.find(params[:id])
      end

      def note_params
        params.require(:note).permit(:title, :content, :user)
      end
    end
  end
end
