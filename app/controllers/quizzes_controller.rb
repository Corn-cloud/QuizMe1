class QuizzesController < ApplicationController
  skip_before_action :authenticated, only: [:index]
 
  def index
    @quizzes = Quiz.all
  end


  def new
    @questions = Question.all
    @quiz = Quiz.new
  end


  def teacher_show
    @participants = @quiz.participants
    
    render 'teacher_show'
  end 

  def student_show
    @participant = @quiz.participant(current_user)
    @user = current_user
    @question = @quiz.next_question(current_user)
    if @question
      render 'student_show'
    else
      render 'student_result'
    end
  end


  def show
    @quiz = Quiz.find(params[:id])

    if @quiz.teacher?(current_user)
      teacher_show
    else
      # first visit? enroll as a student
      if !@quiz.student?(current_user)
        @quiz.participate(current_user)
      end
      student_show
    end

  end


  def create

    thumbnail = params[:quiz][:thumbnail]
    @quiz = Quiz.new(quiz_params)
    if thumbnail && @quiz.save
      @quiz.image_url = @quiz.id.to_s  # write additional image url attribute for further flexibility
      File.open(Rails.root.join('public', 'img/thumbnails', @quiz.image_url), 'wb') do |file|
        file.write(thumbnail.read)
      end
      @quiz.save
      @quiz.assign_teacher_role(current_user)
      redirect_to quiz_path(@quiz)
    else 
      flash[:errors] = @quiz.errors.full_messages + (!thumbnail ? ["Please provide a thumbnail"] : [])
      redirect_to new_quiz_path
    end 
  end 



  def edit
    @quiz = Quiz.find(params[:id])
  end

  def update 
    if @quiz.update
      redirect_to quiz_path(@quiz)
    else 
      flash[:errors] = @quiz.errors.full_messages
      redirect_to new_quiz_path
    end 
  end 

  def quiz_params
    params.require(:quiz).permit(:title , :description ,:question_ids)
  end 
end
