local Animate = {}
Animate.__index = Animate

	function Animate.new(animationId: number, animator: Humanoid | Animator?)
		local trackInstance = Instance.new("Animation")
		trackInstance.AnimationId = "rbxassetid://"..animationId
		trackInstance.Parent = animator
		
		local track: AnimationTrack = animator:LoadAnimation(trackInstance)
		
		local self = setmetatable({
			KeyframeReached = track.KeyframeReached, --Event
			Stopped = track.Stopped, --Event
			DidLoop = track.DidLoop, --Event
			Ended = track.Ended, --Event
			
			TimePosition = track.TimePosition, --ReadOnly
			IsPlaying = track.IsPlaying, --ReadOnly
			Length = track.Length, --ReadOnly
			Speed = track.Speed, --ReadOnly
			
			Priority = track.Priority, --ReadOnly, Set by 'SetPriority' method
			Looped = track.Looped, --ReadOnly, Set by 'Looped' method
			
			animationId = trackInstance.AnimationId,
			animationTrack = track,
			
			_readonly = {
				trackTime = 0,			
				lockTime = 1,
			},
		},Animate)
		
		return self
	end
	
	--Play animation from beginning
	function Animate:Play()
		self:AdjustSpeed()
		self.animationTrack:Play()
	end
	
	--Stops animation and sets track time to 0
	function Animate:Stop()
		self.animationTrack:Stop()
		self:SetPosition(0)
	end
	
	--Pause animation track at a frame
	function Animate:Pause()
		self:SetPosition(self.animationTrack.TimePosition)
		self:AdjustSpeed(0)
	end
	
	--Play animation from beginning
	function Animate:Restart()
		self._readonly.trackTime = 0
		self:Play()
	end
	
	--Defaults to true if boolean is nil
	function Animate:Looped(boolean: boolean?)
		boolean = if boolean == nil then true else boolean
		self.animationTrack.Looped = boolean
	end
	
	--use Enum.AnimationPriority, defaults to Action2
	function Animate:SetPriority(enum: EnumItem)
		enum = if enum == nil then Enum.AnimationPriority.Action2 else enum
		self.animationTrack.Priority = enum
	end
	
	--Reset track time if number is nil
	function Animate:AdjustSpeed(number: number?) 
		if self.animationTrack.Speed ~= 0 then
			self._readonly.lockTime = self.animationTrack.Speed
		end

		if number == nil then
			self.animationTrack:AdjustSpeed(self._readonly.lockTime)
		else
			self.animationTrack:AdjustSpeed(number)
		end
	end

	--will default to 0 if there is no number
	function Animate:SetPosition(number: number?)
		number = if number == nil then 0 else number % self.animationTrack.Length
		self._readonly.trackTime = number
		self.animationTrack.TimePosition = number
	end

return Animate