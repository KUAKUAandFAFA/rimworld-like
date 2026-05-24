class_name JobQueue
extends Node

signal job_added(job: JobInstance)
signal job_claimed(job: JobInstance, pawn: Pawn)
signal job_completed(job: JobInstance)
signal job_failed(job: JobInstance, reason: String)

var _queued_jobs: Array[JobInstance] = []
var _active_jobs: Array[JobInstance] = []


func add_job(job: JobInstance) -> void:
	if job == null:
		return

	job.status = JobInstance.Status.QUEUED
	job.failure_reason = ""
	_queued_jobs.append(job)
	job_added.emit(job)


func claim_next_job(pawn: Pawn) -> JobInstance:
	if pawn == null or _queued_jobs.is_empty():
		return null

	var job := _queued_jobs.pop_front() as JobInstance
	job.status = JobInstance.Status.CLAIMED
	job.assigned_pawn = pawn
	_active_jobs.append(job)
	job_claimed.emit(job, pawn)
	return job


func complete_job(job: JobInstance) -> void:
	if job == null:
		return

	_active_jobs.erase(job)
	job.status = JobInstance.Status.COMPLETED
	job_completed.emit(job)


func fail_job(job: JobInstance, reason: String) -> void:
	if job == null:
		return

	_queued_jobs.erase(job)
	_active_jobs.erase(job)
	job.status = JobInstance.Status.FAILED
	job.failure_reason = reason
	job_failed.emit(job, reason)


func has_queued_jobs() -> bool:
	return not _queued_jobs.is_empty()


func get_active_job_for(pawn: Pawn) -> JobInstance:
	for job in _active_jobs:
		if job.assigned_pawn == pawn:
			return job

	return null
