import SwiftUI

struct PollEngagementView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(SettingsStore.self) private var settings
    @Environment(PollStore.self) private var pollStore
    @Environment(VoiceCommandManager.self) private var voiceCommandsManager
    
    let engagement: Engagement
    let resetAutodismiss: () -> Void
    
    @State private var isVoting = false
    @State private var voteResult: Bool? = nil
    @State private var pollResults: PollResults?
    
    var body: some View {
        VStack(spacing: 24) {
            Text(engagement.description ?? engagement.name ?? "")
                .font(.title.weight(.semibold))
                .minimumScaleFactor(0.1)
                .multilineTextAlignment(.center)
            
            let chooseYes = voteResult == true
            Text(yesButtonTitle)
                .font(.largeTitle.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(chooseYes ? .white : .green)
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .background {
                    if chooseYes {
                        RoundedRectangle(cornerRadius: 16, style: .circular)
                            .fill(Color.green.gradient)
                    } else {
                        ZStack {
                            Color.white
                            Rectangle().fill(Color.green.opacity(0.2).gradient)
                        }
                        .compositingGroup()
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .circular))
                        
                        RoundedRectangle(cornerRadius: 16, style: .circular)
                            .stroke(Color.green, lineWidth: 3)
                    }
                }
                .onTapGesture {
                    saveVote(true)
                }
                .disabled(isVoted || isVoting)
            
            let chooseNo = voteResult == false
            Text(noButtonTitle)
                .font(.largeTitle.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(chooseNo ? .white : .red)
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .background {
                    if chooseNo {
                        RoundedRectangle(cornerRadius: 16, style: .circular)
                            .fill(Color.red.gradient)
                    } else {
                        ZStack {
                            Color.white
                            Rectangle().fill(Color.red.opacity(0.2).gradient)
                        }
                        .compositingGroup()
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .circular))
                        
                        RoundedRectangle(cornerRadius: 16, style: .circular)
                            .stroke(Color.red, lineWidth: 3)
                    }
                }
                .onTapGesture {
                    saveVote(false)
                }
                .disabled(isVoted || isVoting)
            
            Text(isVoted ? "Close" : "Skip")
                .font(.largeTitle.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .background {
                    ZStack {
                        Color.white
                        Rectangle().fill(Color.gray.opacity(0.2).gradient)
                    }
                    .compositingGroup()
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .circular))
                    
                    RoundedRectangle(cornerRadius: 16, style: .circular)
                        .stroke(Color.gray, lineWidth: 3)
                }
                .onTapGesture {
                    dismiss()
                }
        }
        .frame(maxHeight: .infinity)
        .task {
            if settings.voiceCommands {
                for await recognition in voiceCommandsManager.recognitions {
                    handleRecognition(recognition)
                }
            }
        }
    }
    
    private var yesButtonTitle: LocalizedStringKey {
        guard let pollResults else { return "Yes👍" }
        let votesCount = pollResults.numberOfYes + pollResults.numberOfNo
        let percent = Int(Double(pollResults.numberOfYes) / Double(votesCount) * 100)
        return  "Yes👍 - \(percent)%"
    }
    
    private var noButtonTitle: LocalizedStringKey {
        guard let pollResults else { return "No👎"}
        let votesCount = pollResults.numberOfYes + pollResults.numberOfNo
        let percent = Int(Double(pollResults.numberOfNo) / Double(votesCount) * 100)
        return  "No👎 - \(percent)%"
    }
    
    private var isVoted: Bool {
        voteResult != nil
    }
    
    private func handleRecognition(_ value: String) {
        if value.localizedCaseInsensitiveContains("yes") {
            saveVote(true)
        } else if value.localizedCaseInsensitiveContains("no") {
            saveVote(false)
        }
    }
    
    private func saveVote(_ value: Bool) {
        guard let pollId = engagement.info else {
            dismiss()
            return
        }
        
        isVoting = true
        resetAutodismiss()
        withAnimation {
            voteResult = value
        }
        
        Task {
            do {
                pollResults = try await pollStore.saveVote(value: value, pollId: pollId)
                if pollResults == nil {
                    dismiss()
                }
            } catch {
                // TODO: needs better error handling
                dismiss()
            }
        }
    }
}
