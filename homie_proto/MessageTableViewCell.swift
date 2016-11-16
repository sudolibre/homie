import UIKit
import SnapKit

class MessageTableViewCell: UITableViewCell {
    
    
    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.subheadline)
        label.textColor = UIColor.blue
        return label
    }()
    
    lazy var bodyLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
        label.textColor = UIColor.white
        label.numberOfLines = 0
        return label
    }()
    
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        //self.isOwner = isOwner
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureSubviews()
    }

    func configureSubviews() {
        self.addSubview(self.nameLabel)
        self.addSubview(self.bodyLabel)

        nameLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self).offset(10)
            make.left.equalTo(self).offset(20)
            make.right.equalTo(self).offset(-20)
            }

        bodyLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(nameLabel.snp.bottom).offset(1)
            make.left.equalTo(self).offset(20)
            make.right.equalTo(self).offset(-20)
            make.bottom.equalTo(self).offset(-10)
            
        }
        
    }
    // We won’t use this but it’s required for the class to compile
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
