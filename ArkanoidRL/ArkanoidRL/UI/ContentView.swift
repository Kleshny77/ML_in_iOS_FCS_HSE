import SwiftUI
struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var gameManager = GameManager()
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Счет: \(gameManager.score)")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Блоков: \(gameManager.remainingBricks)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 2) {
                        Text("У/Н")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 15) {
                            VStack(spacing: 1) {
                                Text("👨")
                                    .font(.caption)
                                Text("\(gameManager.playerSuccessfulHits)/\(gameManager.playerMissedHits)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(gameManager.playerSuccessfulHits >= gameManager.playerMissedHits ? .green : .red)
                            }
                            
                            VStack(spacing: 1) {
                                Text("🤖")
                                    .font(.caption)
                                Text("\(gameManager.robotSuccessfulHits)/\(gameManager.robotMissedHits)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(gameManager.robotSuccessfulHits >= gameManager.robotMissedHits ? .green : .red)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("Обучение: \(Int(gameManager.trainingProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(gameManager.trainingProgress > 0.7 ? .green : .orange)
                        
                        Text("Исслед.: \(Int(gameManager.explorationRate * 100))%")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.9))
                .padding(.top, 50)
                
                VStack(spacing: 5) {
                    HStack {
                        Text("Примеры: \(gameManager.successfulExamples)")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        
                        Spacer()
                        
                        Text("Ошибка:")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        Text(String(format: "%.3f", gameManager.predictionError))
                            .font(.caption)
                            .foregroundColor(gameManager.predictionError < 0.2 ? .green : .orange)
                        
                        Spacer()
                        
                        Text("Награда:")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        Text(String(format: "%.1f", gameManager.totalReward))
                            .font(.caption)
                            .foregroundColor(gameManager.totalReward > 0 ? .green : .red)
                    }
                    .padding(.horizontal)
                    
                    ProgressView(value: gameManager.trainingProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: gameManager.trainingProgress > 0.7 ? .green : .orange))
                        .padding(.horizontal)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(3)
                }
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.7))
                
                GeometryReader { geometry in
                    ZStack {
                        Color.black

                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            .padding(1)

                        ForEach(gameManager.bricks) { brick in
                            if !brick.isDestroyed {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(brick.color)
                                    .frame(width: brick.width, height: brick.height)
                                    .position(x: brick.position.x, y: brick.position.y)
                            }
                        }
                        
                        if gameManager.showModelPrediction && gameManager.isRobotPlaying {
                            Path { path in
                                let start = gameManager.ballPosition
                                let end = CGPoint(x: gameManager.predictedPlatformPosition,
                                                 y: gameManager.platformPosition.y)
                                path.move(to: start)
                                path.addLine(to: end)
                            }
                            .stroke(Color.yellow.opacity(0.3), style: StrokeStyle(
                                lineWidth: 1,
                                dash: [3, 3]
                            ))

                            Circle()
                                .fill(Color.yellow.opacity(0.5))
                                .frame(width: 8, height: 8)
                                .position(x: gameManager.predictedPlatformPosition,
                                         y: gameManager.platformPosition.y)
                        }
                        
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [.red, .orange]),
                                    center: .center,
                                    startRadius: 2,
                                    endRadius: 10
                                )
                            )
                            .frame(width: gameManager.ballSize, height: gameManager.ballSize)
                            .shadow(color: .red.opacity(0.5), radius: 3)
                            .position(gameManager.ballPosition)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.white, .gray.opacity(0.8)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: gameManager.platformWidth, height: gameManager.platformHeight)
                            .overlay(
                                Capsule()
                                    .stroke(gameManager.isRobotPlaying ? Color.blue : Color.green, lineWidth: 2)
                            )
                            .shadow(color: gameManager.isRobotPlaying ? .blue.opacity(0.7) : .green.opacity(0.7), radius: 3)
                            .position(gameManager.platformPosition)
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                if !gameManager.isRobotPlaying {
                                    let newX = min(max(value.location.x, gameManager.platformWidth/2),
                                                 geometry.size.width - gameManager.platformWidth/2)
                                    gameManager.movePlatform(to: newX)
                                }
                            }
                    )
                    .onAppear {
                        gameManager.setupGame(in: geometry.size)
                    }
                }
                
                VStack(spacing: 10) {
                    HStack(spacing: 20) {
                        Text(gameManager.isRobotPlaying ? "🤖 Робот" : "👨 Человек")
                            .font(.caption)
                            .foregroundColor(gameManager.isRobotPlaying ? .blue : .green)
                            .lineLimit(1)

                        Spacer()

                        controlToggle(
                            title: "Робот",
                            isOn: $gameManager.isRobotPlaying,
                            tint: .blue
                        )

                        if gameManager.isRobotPlaying {
                            controlToggle(
                                title: "Предск.",
                                isOn: $gameManager.showModelPrediction,
                                tint: .yellow
                            )
                        }
                    }

                    HStack(spacing: 16) {
                        Button("Новая игра") {
                            gameManager.resetGame()
                        }
                        .font(.caption)
                        .foregroundColor(.red)

                        Spacer()

                        Button("Сброс обучения") {
                            gameManager.resetTraining()
                        }
                        .font(.caption)
                        .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.9))
                .padding(.bottom, 20)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            gameManager.startTraining()
        }
        .onDisappear {
            gameManager.saveModel()
        }
        .onChange(of: scenePhase) { newPhase in
            gameManager.handleScenePhaseChange(newPhase)
        }
    }

    private func controlToggle(title: String, isOn: Binding<Bool>, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)
                .lineLimit(1)

            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: tint))
        }
        .fixedSize()
    }
}
