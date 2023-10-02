-- rescale chat
return function (horizontalAlignment: Enum.HorizontalAlignment,verticalAlignment: Enum.VerticalAlignment,heightScale: number,widthScale: number)
	local horizAlign = horizontalAlignment or Enum.HorizontalAlignment.Left
	local vertAlign = verticalAlignment or Enum.VerticalAlignment.Top
	local height = heightScale or 1
	local width = widthScale or 1

	game.TextChatService.ChatWindowConfiguration.HorizontalAlignment = horizAlign
	game.TextChatService.ChatWindowConfiguration.VerticalAlignment = vertAlign
	game.TextChatService.ChatWindowConfiguration.HeightScale = height
	game.TextChatService.ChatWindowConfiguration.WidthScale = width
end