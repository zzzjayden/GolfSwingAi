import SwiftUI

// MARK: - Drill Model
struct Drill: Identifiable {
    let id = UUID()
    let imageName: String
    let title: String
    let description: String
    let youtubeURL: URL
}

// MARK: - DrillTile View
struct DrillTile: View {
    let imageName: String
    let title: String
    let description: String
    let youtubeURL: URL
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                UIApplication.shared.open(youtubeURL)
            }) {
                ZStack(alignment: .bottomLeading) {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 250, height: 150)
                        .clipped()
                        .cornerRadius(16)
                    
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                        .padding([.leading, .bottom], 10)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(isExpanded ? "Hide Tip" : "Show Tip")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .padding(.top, 6)
            }
            
            if isExpanded {
                VStack(alignment: .leading) {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(width: 250)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
        .padding(.vertical)
        .animation(.easeInOut, value: isExpanded)
    }
}

// MARK: - Drill Section View
struct DrillSection: View {
    let title: String
    let drills: [Drill]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.title2)
                .bold()
                .padding([.leading, .top])
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(drills) { drill in
                        DrillTile(
                            imageName: drill.imageName,
                            title: drill.title,
                            description: drill.description,
                            youtubeURL: drill.youtubeURL
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Drills Page (Main Entry)
struct Drillspage: View {
    
    let setupDrills = [
        Drill(
            imageName: "GrantHorvat",
            title: "How to set up for Driver",
            description: "Grant Horvat shows the basics of how to setup to a driver swing, including the proper grip, stance, and ball position. -TaylorMade Golf. Click picture to see more",
            youtubeURL: URL(string: "https://youtu.be/LSxEO9iZbD4?si=W8yAVxddpwNYvcjo&t=45")!
        ),
        
        Drill(
            imageName: "TommyFleetwood",
            title: "How to set up for an iron shot",
            description: "Tommy Fleetwood recommends keeping a neutral setup and ball position slightly forward of center, starting the takeaway with a body turn to avoid going outside, maintaining a strong left side at the top, and initiating the downswing by driving the left hip straight back and down to create space and proper sequencing through impact. -TaylorMade Golf. Click picture to see more",
            youtubeURL: URL(string: "https://www.youtube.com/watch?v=Kh50UfMS_Qc")!
        )
    ]
    
    let backSwingDrills = [
        Drill(
            imageName: "TeeUnderArm",
            title: "Tees under arm Drill",
            description: "This drill is for you if your arms are coming up on the backswing. A drill would include putting a tee or a glove under your trail arm, forcing you to pin your elbow to your side. - HackMotion, Click picture to see more",
            youtubeURL: URL(string: "https://youtu.be/MNwxIfjsJ3s?si=AelHCWqGNswlhiAm&t=520")!
        ),
        Drill(
            imageName: "ChairDrill",
            title: "Hip Sway Drill",
            description: "Create a backstop near your trail leg to make sure that you're not swaying into it. - HackMotion Click picture to see more",
            youtubeURL: URL(string: "https://youtu.be/MNwxIfjsJ3s?si=KlTHLLqencKok6cz&t=289")!
        ),
        Drill(
            imageName: "Towerl",
            title: "Towel Drill",
            description: "This drill teaches golfers how to keep your arms closer to body. This helps with your setup as well as your swing to make sure your maintaining a correct posture. - PorzakGolf",
            youtubeURL: URL(string: "https://www.youtube.com/shorts/Igk_OFc9iyA")!
        )
    ]
    
    let downSwingDrills = [
        Drill(
            imageName: "SkippingRock",
            title: "Over the top fix",
            description: "This is a drill to help you fix the over the top motion, Justin Rose encourages that you create a skipping rock motion when you are swinging to encourage an in to out path. - GolfDigest, Click picture to see more",
            youtubeURL: URL(string: "https://www.youtube.com/shorts/CV21m4AUKQY")!
        ),
        
        Drill(
            imageName: "StepThrough",
            title: "Proper weight transfer",
            description: "This is a drill that teached a golfer how to properly transfer your weight during the golf swing. At setup you have your normal stance but in your back swing you narrow your stance and on the down swing you take a leap forward with your leading foot - Titleist, Click picture to see more",
            youtubeURL: URL(string: "https://www.youtube.com/watch?v=D6zQpaZezhI")!
        )
    ]
    
    let followThroughDrills = [
        Drill(
            imageName: "Maria",
            title: "3 Follow through Checkpoints",
            description: "Maria Pelozola’s explains her three checkpoints for completing the golf swing, 1. Back foot on toe, 2. Squeezing the knees, and 3. Club shaft behind the head and across the ears. - mygolfinstructor, Click picture to see more",
            youtubeURL: URL(string: "https://youtu.be/FngZYiH5V4o?si=PwPOw88DbF-2Bq1a&t=59")!
        )
        
        
//        
//        Drill(
//            imageName: "",
//            title: "Bleh",
//            description: "This drill focuses on completing your swing with balance and control.",
//            youtubeURL: URL(string: "https://youtu.be/MNwxIfjsJ3s?si=AelHCWqGNswlhiAm&t=520")!
//        )
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                DrillSection(title: "How to Setup", drills: setupDrills)
                DrillSection(title: "Backswing Drills", drills: backSwingDrills)
                DrillSection(title: "Downswing Drills", drills: downSwingDrills)
                DrillSection(title: "Followthrough Drills", drills: followThroughDrills)
            }
            .padding(.bottom)
        }
        .navigationTitle("Drills")
    }
}

// MARK: - Preview
#Preview {
    Drillspage()
}
